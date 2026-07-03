DROP TABLE IF EXISTS app_events;

CREATE TABLE app_events (
    event_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INTEGER NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    event_date DATE NOT NULL,
    amount NUMERIC(10, 2) NOT NULL
);

INSERT INTO app_events (user_id, event_type, event_date, amount)
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

ANALYZE app_events;

SELECT COUNT(*) AS total_rows
FROM app_events;

EXPLAIN
SELECT *
FROM app_events
WHERE user_id = 500;

CREATE INDEX idx_app_events_user_id
ON app_events (user_id);

EXPLAIN
SELECT *
FROM app_events
WHERE user_id = 500;

EXPLAIN
SELECT *
FROM app_events
WHERE user_id = 1000;

EXPLAIN
SELECT *
FROM app_events
WHERE event_type = 'purchase';

EXPLAIN
SELECT *
FROM app_events
WHERE amount > 400;

EXPLAIN ANALYZE
SELECT *
FROM app_events
WHERE user_id = 500;

EXPLAIN ANALYZE
SELECT *
FROM app_events
WHERE event_type = 'purchase';

CREATE INDEX idx_app_events_event_type
ON app_events (event_type);

ANALYZE app_events;

EXPLAIN ANALYZE
SELECT *
FROM app_events
WHERE event_type = 'purchase';

EXPLAIN ANALYZE
SELECT *
FROM app_events
WHERE amount > 400;

CREATE INDEX idx_app_events_amount
ON app_events (amount);

ANALYZE app_events;

EXPLAIN ANALYZE
SELECT *
FROM app_events
WHERE amount > 400;

EXPLAIN ANALYZE
SELECT *
FROM app_events
WHERE user_id = 500
  AND event_date >= DATE '2025-06-01';

CREATE INDEX idx_app_events_user_id_event_date
ON app_events (user_id, event_date);

ANALYZE app_events;

EXPLAIN ANALYZE
SELECT *
FROM app_events
WHERE user_id = 500
  AND event_date >= DATE '2025-06-01';