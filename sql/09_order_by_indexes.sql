DROP TABLE IF EXISTS app_events_order_test;

CREATE TABLE app_events_order_test (
    event_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INTEGER NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    event_date DATE NOT NULL,
    amount NUMERIC(10, 2) NOT NULL
);

INSERT INTO app_events_order_test (user_id, event_type, event_date, amount)
SELECT
    (random() * 10000)::INTEGER + 1 AS user_id,
    CASE
        WHEN random() < 0.4 THEN 'page_view'
        WHEN random() < 0.7 THEN 'click'
        WHEN random() < 0.9 THEN 'purchase'
        ELSE 'refund'
    END AS event_type,
    DATE '2025-01-01' + ((random() * 364)::INTEGER) AS event_date,
    ROUND((random() * 500)::NUMERIC, 2) AS amount
FROM generate_series(1, 200000);

ANALYZE app_events_order_test;

EXPLAIN ANALYZE
SELECT *
FROM app_events_order_test
ORDER BY event_date
LIMIT 20;

CREATE INDEX idx_app_events_order_test_event_date
ON app_events_order_test (event_date);

ANALYZE app_events_order_test;

EXPLAIN ANALYZE
SELECT *
FROM app_events_order_test
ORDER BY event_date
LIMIT 20;