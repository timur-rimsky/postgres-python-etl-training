SELECT
    s.full_name,
    c.course_name,
    e.enrollment_date,
    e.status
FROM enrollments e
JOIN students s ON e.student_id = s.student_id
JOIN courses c ON e.course_id = c.course_id;


SELECT
    c.course_name,
    COUNT(e.student_id) AS students_count
FROM courses c
LEFT JOIN enrollments e ON c.course_id = e.course_id
GROUP BY c.course_name
ORDER BY students_count DESC;


SELECT
    c.course_name,
    COUNT(e.student_id) AS students_count,
    SUM(c.price) AS total_revenue
FROM courses c
LEFT JOIN enrollments e ON c.course_id = e.course_id
GROUP BY c.course_name
ORDER BY total_revenue DESC;