DROP TABLE IF EXISTS insert_test_no_index;
DROP TABLE IF EXISTS insert_test_with_index;

CREATE TABLE insert_test_no_index (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INTEGER NOT NULL,
    event_date DATE NOT NULL,
    amount NUMERIC(10, 2) NOT NULL
);

CREATE TABLE insert_test_with_index (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INTEGER NOT NULL,
    event_date DATE NOT NULL,
    amount NUMERIC(10, 2) NOT NULL
);

CREATE INDEX idx_insert_test_user_id
ON insert_test_with_index (user_id);

CREATE INDEX idx_insert_test_event_date
ON insert_test_with_index (event_date);

CREATE INDEX idx_insert_test_amount
ON insert_test_with_index (amount);

EXPLAIN ANALYZE
INSERT INTO insert_test_no_index (user_id, event_date, amount)
SELECT
    (random() * 10000)::INTEGER + 1,
    DATE '2025-01-01' + ((random() * 364)::INTEGER),
    ROUND((random() * 500)::NUMERIC, 2)
FROM generate_series(1, 200000);

EXPLAIN ANALYZE
INSERT INTO insert_test_with_index (user_id, event_date, amount)
SELECT
    (random() * 10000)::INTEGER + 1,
    DATE '2025-01-01' + ((random() * 364)::INTEGER),
    ROUND((random() * 500)::NUMERIC, 2)
FROM generate_series(1, 200000);