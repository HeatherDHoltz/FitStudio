BEGIN;

CREATE TABLE studio (
    studio_id INTEGER PRIMARY KEY,
    studio_name VARCHAR(100) NOT NULL,
    address VARCHAR(255) NOT NULL
);
CREATE TABLE instructor (
    instructor_id INTEGER PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    CONSTRAINT instructor_email_uq UNIQUE (email)
);
CREATE TABLE member (
    member_id INTEGER PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL
);
CREATE TABLE class_session (
    class_session_id INTEGER PRIMARY KEY,
    starts_at TIMESTAMPTZ NOT NULL,
    capacity INTEGER NOT NULL,
    studio_id INTEGER NOT NULL,
    instructor_id INTEGER NOT NULL,
    CONSTRAINT check_session_capacity CHECK (capacity > 0),
    CONSTRAINT session_studio_fk FOREIGN KEY (studio_id)
        REFERENCES studio(studio_id) ON DELETE RESTRICT,
    CONSTRAINT session_instructor_fk FOREIGN KEY (instructor_id)
        REFERENCES instructor(instructor_id) ON DELETE RESTRICT
);
CREATE TABLE pass (
    member_id INTEGER NOT NULL,
    pass_no INTEGER NOT NULL,
    total_credits INTEGER NOT NULL,
    purchased_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pass_pk PRIMARY KEY (member_id, pass_no),
    CONSTRAINT pass_member_fk FOREIGN KEY (member_id)
        REFERENCES member(member_id) ON DELETE RESTRICT,
    CONSTRAINT check_pass_number CHECK (pass_no > 0),
    CONSTRAINT check_pass_credits CHECK (total_credits > 0)
);
CREATE TABLE booking (
    member_id INTEGER NOT NULL,
    pass_no INTEGER NOT NULL,
    class_session_id INTEGER NOT NULL,
    status VARCHAR(10) NOT NULL DEFAULT 'BOOKED',
    booked_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cancelled_at TIMESTAMPTZ,
    CONSTRAINT booking_pk PRIMARY KEY (member_id, pass_no, class_session_id),
    CONSTRAINT booking_pass_fk FOREIGN KEY (member_id, pass_no)
        REFERENCES pass(member_id, pass_no) ON DELETE RESTRICT,
    CONSTRAINT booking_session_fk FOREIGN KEY (class_session_id)
        REFERENCES class_session(class_session_id) ON DELETE RESTRICT,
    CONSTRAINT check_booking_status CHECK (status IN ('BOOKED', 'CANCELLED')),
    CONSTRAINT check_booking_cancelled_at CHECK (
        (status = 'BOOKED' AND cancelled_at IS NULL)
        OR (status = 'CANCELLED' AND cancelled_at IS NOT NULL
            AND cancelled_at >= booked_at)
    )
);

CREATE UNIQUE INDEX booking_one_active_per_member_session
    ON booking (member_id, class_session_id)
    WHERE status = 'BOOKED';

CREATE VIEW pass_credit_balance AS
SELECT
    p.member_id,
    p.pass_no,
    p.total_credits,
    COUNT(b.class_session_id) FILTER (
        WHERE b.status = 'BOOKED'
    ) AS used_credits,
    p.total_credits -
    COUNT(b.class_session_id) FILTER (
        WHERE b.status = 'BOOKED'
    ) AS remaining_credits
FROM pass p
LEFT JOIN booking b
    ON p.member_id = b.member_id
   AND p.pass_no = b.pass_no
GROUP BY
    p.member_id,
    p.pass_no,
    p.total_credits;

CREATE OR REPLACE FUNCTION validate_booking()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    class_start class_session.starts_at%TYPE;
    class_capacity class_session.capacity%TYPE;
    pass_credits pass.total_credits%TYPE;
    active_count BIGINT;
BEGIN
    IF TG_OP = 'UPDATE' THEN
        -- Keep the booking's identifying keys fixed.
        IF ROW(NEW.member_id, NEW.pass_no, NEW.class_session_id)
           IS DISTINCT FROM
           ROW(OLD.member_id, OLD.pass_no, OLD.class_session_id)
        THEN
            RAISE EXCEPTION
                'Cancel the booking and create another to change its member, pass, or class';
        END IF;

        -- An existing active booking consumes no additional credit or seat.
        IF OLD.status = 'BOOKED' AND NEW.status = 'BOOKED' THEN
            RETURN NEW;
        END IF;
    END IF;

    -- Allow cancellation without requiring available credits or seats.
    IF NEW.status IS DISTINCT FROM 'BOOKED' THEN
        RETURN NEW;
    END IF;

    -- Lock the class first to protect its remaining seats.
    SELECT starts_at, capacity
    INTO class_start, class_capacity
    FROM class_session
    WHERE class_session_id = NEW.class_session_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Class session does not exist';
    END IF;

    IF class_start <= clock_timestamp() THEN
        RAISE EXCEPTION 'Cannot book a class that has already started';
    END IF;

    SELECT COUNT(*)
    INTO active_count
    FROM booking
    WHERE class_session_id = NEW.class_session_id
      AND status = 'BOOKED';

    IF active_count >= class_capacity THEN
        RAISE EXCEPTION 'This class is full';
    END IF;

    -- Lock the pass second to protect its remaining credits.
    SELECT total_credits
    INTO pass_credits
    FROM pass
    WHERE member_id = NEW.member_id
      AND pass_no = NEW.pass_no
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Selected pass does not exist for this member';
    END IF;

    SELECT COUNT(*)
    INTO active_count
    FROM booking
    WHERE member_id = NEW.member_id
      AND pass_no = NEW.pass_no
      AND status = 'BOOKED';

    IF active_count >= pass_credits THEN
        RAISE EXCEPTION 'This pass has no remaining credits';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER booking_validation_trigger
BEFORE INSERT OR UPDATE ON booking
FOR EACH ROW
EXECUTE FUNCTION validate_booking();

COMMIT;
