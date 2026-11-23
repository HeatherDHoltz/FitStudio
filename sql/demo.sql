SELECT * FROM member WHERE member_id = 901;
SELECT * FROM class_session WHERE starts_at > CURRENT_TIMESTAMP;
SELECT * FROM booking ORDER BY member_id, pass_no, class_session_id;
SELECT * FROM pass_credit_balance ORDER BY member_id, pass_no;
SELECT c.class_session_id, c.capacity, count(b.class_session_id) AS booked
FROM class_session c LEFT JOIN booking b
ON c.class_session_id=b.class_session_id AND b.status='BOOKED'
GROUP BY c.class_session_id, c.capacity ORDER BY c.class_session_id;

-- Step 4: Successful booking and remaining credits
SELECT b.class_session_id, b.status, p.remaining_credits
FROM booking b
JOIN pass_credit_balance p USING (member_id, pass_no)
WHERE b.member_id = 1 AND b.pass_no = 2 AND b.class_session_id = 201;

-- Step 5: One seat and one committed booking
SELECT c.class_session_id, c.capacity, COUNT(b.member_id) AS booked_seats
FROM class_session c
LEFT JOIN booking b
    ON b.class_session_id = c.class_session_id AND b.status = 'BOOKED'
WHERE c.class_session_id = 202
GROUP BY c.class_session_id, c.capacity;
