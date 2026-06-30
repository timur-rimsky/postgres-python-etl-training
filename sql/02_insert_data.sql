INSERT INTO students (full_name, age, city)
VALUES
    ('Ivan Petrov', 21, 'Moscow'),
    ('Anna Smirnova', 24, 'Saint Petersburg'),
    ('Pavel Sokolov', 19, 'Kazan');

INSERT INTO courses (course_name, category, price)
VALUES
    ('Python Basics', 'Programming', 15000.00),
    ('SQL for Analytics', 'Databases', 12000.00),
    ('Data Engineering Intro', 'Data Engineering', 18000.00);

INSERT INTO enrollments (student_id, course_id, enrollment_date, status)
VALUES
    (1, 1, '2026-06-01', 'active'),
    (1, 2, '2026-06-05', 'active'),
    (2, 2, '2026-06-10', 'completed'),
    (3, 3, '2026-06-15', 'active');