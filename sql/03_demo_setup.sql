INSERT INTO class_session (class_session_id, starts_at, capacity, studio_id, instructor_id)
VALUES
    (201, CURRENT_TIMESTAMP + INTERVAL '7 days', 2, 1, 1),
    (202, CURRENT_TIMESTAMP + INTERVAL '7 days 1 hour', 1, 1, 1);
