DROP TABLE IF EXISTS etl_students_upsert;

CREATE TABLE etl_students_upsert (
    student_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    external_student_id INTEGER NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    city VARCHAR(50),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO etl_students_upsert (
    external_student_id,
    full_name,
    email,
    city
)
VALUES
    (101, 'Anna Smirnova', 'anna@example.com', 'Moscow'),
    (102, 'Pavel Orlov', 'pavel@example.com', 'Kazan'),
    (103, 'Elena Petrova', 'elena@example.com', 'Rostov');

SELECT *
FROM etl_students_upsert
ORDER BY external_student_id;

INSERT INTO etl_students_upsert (
    external_student_id,
    full_name,
    email,
    city
)
VALUES
    (101, 'Anna Smirnova', 'anna_new@example.com', 'Saint Petersburg')
ON CONFLICT (external_student_id)
DO UPDATE SET
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    city = EXCLUDED.city,
    updated_at = CURRENT_TIMESTAMP;

SELECT *
FROM etl_students_upsert
ORDER BY external_student_id;

INSERT INTO etl_students_upsert (
    external_student_id,
    full_name,
    email,
    city
)
VALUES
    (101, 'Anna Smirnova', 'anna_final@example.com', 'Moscow'),
    (102, 'Pavel Orlov', 'pavel_new@example.com', 'Nizhny Novgorod'),
    (104, 'Ivan Sokolov', 'ivan@example.com', 'Tula'),
    (105, 'Maria Volkova', 'maria@example.com', 'Sochi')
ON CONFLICT (external_student_id)
DO UPDATE SET
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    city = EXCLUDED.city,
    updated_at = CURRENT_TIMESTAMP;

SELECT *
FROM etl_students_upsert
ORDER BY external_student_id;

INSERT INTO etl_students_upsert (
    external_student_id,
    full_name,
    email,
    city
)
VALUES
    (101, 'Anna Smirnova', 'anna_final@example.com', 'Moscow'),
    (102, 'Pavel Orlov', 'pavel_new@example.com', 'Nizhny Novgorod'),
    (103, 'Elena Petrova', 'elena_changed@example.com', 'Rostov')
ON CONFLICT (external_student_id)
DO UPDATE SET
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    city = EXCLUDED.city,
    updated_at = CURRENT_TIMESTAMP
WHERE
    etl_students_upsert.full_name IS DISTINCT FROM EXCLUDED.full_name
    OR etl_students_upsert.email IS DISTINCT FROM EXCLUDED.email
    OR etl_students_upsert.city IS DISTINCT FROM EXCLUDED.city;

SELECT *
FROM etl_students_upsert
ORDER BY external_student_id;