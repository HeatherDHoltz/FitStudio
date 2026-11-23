BEGIN;
INSERT INTO studio VALUES
 (1, 'Downtown Fitness', '100 First Street, San Jose'),
 (2, 'Northside Fitness', '200 Second Street, San Jose');
INSERT INTO instructor VALUES
 (1, 'alex@example.com', 'Alex', 'Rivera'),
 (2, 'sam@example.com', 'Sam', 'Chen');
INSERT INTO member VALUES
 (1, 'Jordan', 'Lee'), (2, 'Taylor', 'Patel'), (3, 'Casey', 'Nguyen');
INSERT INTO class_session VALUES
 (101, CURRENT_DATE + INTERVAL '2 days 9 hours', 12, 1, 1),
 (102, CURRENT_DATE + INTERVAL '2 days 10 hours', 10, 1, 2),
 (103, CURRENT_DATE + INTERVAL '3 days 9 hours', 15, 2, 1),
 (104, CURRENT_DATE + INTERVAL '3 days 10 hours', 8, 2, 2);
INSERT INTO pass VALUES
 (1, 1, 2, '2026-10-30 12:00:00-07'),
 (1, 2, 5, '2026-10-31 12:00:00-07'),
 (2, 1, 1, '2026-10-30 12:00:00-07'),
 (3, 1, 3, '2026-10-30 12:00:00-07');
INSERT INTO booking VALUES
 (1, 1, 101, 'BOOKED', '2026-11-01 12:00:00-08', NULL),
 (1, 2, 102, 'CANCELLED', '2026-11-01 12:05:00-08', '2026-11-01 13:00:00-08'),
 (3, 1, 101, 'BOOKED', '2026-11-01 12:10:00-08', NULL);
COMMIT;
