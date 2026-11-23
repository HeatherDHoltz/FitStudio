import configparser
import os
from pathlib import Path

import psycopg

SEARCH = """
SELECT c.class_session_id, c.starts_at, c.capacity,
       i.first_name || ' ' || i.last_name AS instructor,
       c.capacity - (SELECT count(*) FROM booking b
                     WHERE b.class_session_id = c.class_session_id
                       AND b.status = 'BOOKED') AS remaining_seats
FROM class_session c JOIN instructor i USING (instructor_id)
WHERE c.studio_id = %s AND c.starts_at >= %s::timestamptz
ORDER BY c.starts_at
"""


def connect():
    settings = configparser.ConfigParser(interpolation=None)
    settings.read(Path(__file__).with_name("db.ini"))
    values = dict(settings["postgres"]) if settings.has_section("postgres") else {}
    return psycopg.connect(os.environ.get("FITSTUDIO_DSN", ""), **values)


def show(cursor):
    print(" | ".join(column.name for column in cursor.description))
    for row in cursor:
        print(" | ".join(str(value) for value in row))


def booking_key():
    return tuple(int(input(label + ": ")) for label in
                 ("Member ID", "Pass number", "Class session ID"))


def main():
    try:
        with connect() as conn:
            print("Connected to", conn.info.dbname)
    except psycopg.Error as error:
        print("Connection failed:", str(error).splitlines()[0])
        return
    while True:
        print("\nFitStudio\n1 Register member\n2 Search classes\n3 Book class\n4 Cancel booking\n5 Show pass balance\n6 Explain search\n0 Exit")
        try:
            choice = input("Choose: ").strip()
            if choice == "0":
                return
            with connect() as conn:
                if choice == "1":
                    member = int(input("Member ID: "))
                    first = input("First name: ").strip()
                    last = input("Last name: ").strip()
                    if not first or not last:
                        raise ValueError("Names are required.")
                    conn.execute("INSERT INTO member VALUES (%s,%s,%s)", (member, first, last))
                elif choice in ("2", "6"):
                    studio = int(input("Studio ID: "))
                    start = input("Starting at (YYYY-MM-DD, blank for now): ").strip() or "now"
                    query = SEARCH
                    if choice == "6":
                        query = "EXPLAIN (ANALYZE, BUFFERS) " + query
                    show(conn.execute(query, (studio, start)))
                elif choice == "3":
                    key = booking_key()
                    pause = input("Pause before commit for two-terminal demo? (y/N): ").lower() == "y"
                    conn.execute("""INSERT INTO booking
                        (member_id, pass_no, class_session_id) VALUES (%s,%s,%s)""", key)
                    if pause:
                        input("Booking pending. Start the second request, then press Enter to commit: ")
                elif choice == "4":
                    cursor = conn.execute("""UPDATE booking
                        SET status='CANCELLED', cancelled_at=clock_timestamp()
                        WHERE member_id=%s AND pass_no=%s AND class_session_id=%s
                          AND status='BOOKED'""", booking_key())
                    if cursor.rowcount == 0:
                        print("No active booking found.")
                elif choice == "5":
                    member = int(input("Member ID: "))
                    show(conn.execute("SELECT * FROM pass_credit_balance WHERE member_id=%s ORDER BY pass_no", (member,)))
                else:
                    print("Choose 0 through 6.")
                    continue
            if choice in ("1", "3", "4"):
                print("Committed.")
        except psycopg.Error as error:
            print("Rejected:", error.diag.message_primary or str(error).splitlines()[0])
        except ValueError as error:
            print("Invalid input:", error)
        except (EOFError, KeyboardInterrupt):
            print("\nExited. Any pending transaction was rolled back.")
            return


if __name__ == "__main__":
    main()
