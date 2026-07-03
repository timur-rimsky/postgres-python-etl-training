# PostgreSQL and Python ETL Training

This repository contains a practical training project focused on PostgreSQL, SQL, and Python-based ETL workflows.

The project demonstrates how raw CSV data can be imported, validated, transformed, loaded into PostgreSQL, logged, and checked for data quality issues.

## Main Focus

The main goal of this project is to practice junior-level Data Engineering skills:

- PostgreSQL table design
- SQL DDL and DML operations
- constraints and relational integrity
- CSV import into PostgreSQL
- staging, clean, and rejected data flows
- indexes and query plan analysis
- Python connection to PostgreSQL
- CSV validation with Python
- UPSERT logic with `ON CONFLICT`
- idempotent ETL loading
- load logs and rejected rows tracking
- transaction handling with `commit()` and `rollback()`

## Project Structure

```text
postgres_training/
│
├── data/
│   ├── new_students.csv
│   └── raw_students.csv
│
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_insert_data.sql
│   ├── 03_queries.sql
│   ├── 04_postgres_features.sql
│   ├── 05_copy_import.sql
│   ├── 06_staging_import.sql
│   ├── 07_relations.sql
│   ├── 08_indexes_explain.sql
│   ├── 09_order_by_indexes.sql
│   ├── 10_indexes_insert_cost.sql
│   └── 11_upsert_on_conflict.sql
│
├── 08_python_postgres_etl/
│   ├── data/
│   │   ├── raw_students.csv
│   │   ├── students.csv
│   │   └── students_upsert.csv
│   │
│   └── scripts/
│       ├── 01_db_connection.py
│       ├── 02_create_insert_read.py
│       ├── 03_transaction_rollback.py
│       ├── 04_env_connection.py
│       ├── 05_executemany_insert.py
│       ├── 06_csv_to_postgres.py
│       ├── 07_csv_validation.py
│       ├── 08_refactored_etl.py
│       └── 09_csv_upsert_to_postgres.py
│
├── .env.example
├── .gitignore
├── requirements.txt
└── README.md
```

## Technologies Used

- Python
- PostgreSQL
- SQL
- psycopg2
- python-dotenv
- CSV files

## SQL Training Blocks

The `sql/` folder contains PostgreSQL practice files.

| File | Topic |
|---|---|
| `01_create_tables.sql` | Basic table creation |
| `02_insert_data.sql` | Insert operations |
| `03_queries.sql` | Basic queries |
| `04_postgres_features.sql` | PostgreSQL-specific features |
| `05_copy_import.sql` | CSV import with `COPY` / `\copy` |
| `06_staging_import.sql` | Staging table import flow |
| `07_relations.sql` | Relations and foreign keys |
| `08_indexes_explain.sql` | Indexes and `EXPLAIN` |
| `09_order_by_indexes.sql` | Indexes for sorting and `ORDER BY` |
| `10_indexes_insert_cost.sql` | Insert cost of indexes |
| `11_upsert_on_conflict.sql` | UPSERT with `ON CONFLICT` |

### SQL topics covered

- `CREATE TABLE`
- `INSERT`, `UPDATE`, `DELETE`
- `PRIMARY KEY`
- `FOREIGN KEY`
- `UNIQUE`
- `CHECK`
- `DEFAULT`
- identity columns
- staging tables
- clean and rejected records
- load logs
- joins and relationships
- indexes
- `EXPLAIN` and `EXPLAIN ANALYZE`
- UPSERT with `ON CONFLICT`

## Python ETL Training Blocks

The Python practice is located in:

```text
08_python_postgres_etl/scripts/
```

| File | Description |
|---|---|
| `01_db_connection.py` | Checks Python connection to PostgreSQL |
| `02_create_insert_read.py` | Creates a table, inserts rows, and reads data back |
| `03_transaction_rollback.py` | Demonstrates transaction rollback after a failed insert |
| `04_env_connection.py` | Connects to PostgreSQL using environment variables |
| `05_executemany_insert.py` | Inserts multiple rows using `executemany()` |
| `06_csv_to_postgres.py` | Reads a clean CSV file and loads it into PostgreSQL |
| `07_csv_validation.py` | Validates raw CSV data and separates clean/rejected rows |
| `08_refactored_etl.py` | Refactored ETL script with functions, clean rows, rejected rows, and logs |
| `09_csv_upsert_to_postgres.py` | CSV to PostgreSQL ETL with validation, UPSERT, load logs, rejected rows tracking, and foreign key integrity |

## Main ETL Script

The main script is:

```text
08_python_postgres_etl/scripts/09_csv_upsert_to_postgres.py
```

It implements a CSV to PostgreSQL ETL pipeline with:

- CSV reading
- row validation
- clean/rejected split
- UPSERT into a clean table
- idempotent loading
- ETL load logs
- rejected rows tracking
- foreign key relationship between rejected rows and load logs
- transaction handling
- basic type hints

## ETL Flow

```text
students_upsert.csv
        ↓
Python CSV reader
        ↓
validation
        ↓
valid rows                invalid rows
        ↓                       ↓
py_students_upsert         py_students_upsert_rejected
        ↓                       ↓
UPSERT logic               linked to load_log_id
        ↓                       ↓
py_students_upsert_load_logs
```

## Validation Rules

A row is considered valid if:

- `external_student_id` can be converted to an integer
- `full_name` is not empty
- `email` is not empty

Rejected rows are saved with a rejection reason:

- `invalid external_student_id`
- `empty full_name`
- `empty email`

## Database Tables Used by the Main ETL Script

### `py_students_upsert`

Stores clean student records.

| Column | Type | Purpose |
|---|---|---|
| `student_id` | `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY` | Internal student ID |
| `external_student_id` | `INTEGER NOT NULL UNIQUE` | External business key from CSV |
| `full_name` | `VARCHAR(100) NOT NULL` | Student name |
| `email` | `VARCHAR(100) NOT NULL` | Student email |
| `city` | `VARCHAR(50)` | Student city |
| `updated_at` | `TIMESTAMP DEFAULT CURRENT_TIMESTAMP` | Last insert/update timestamp |

### `py_students_upsert_load_logs`

Stores one row per ETL load attempt.

| Column | Type | Purpose |
|---|---|---|
| `log_id` | `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY` | Load log ID |
| `source_file` | `VARCHAR(255) NOT NULL` | Source CSV filename |
| `total_rows` | `INTEGER NOT NULL` | Total rows read from CSV |
| `valid_rows` | `INTEGER NOT NULL` | Rows that passed validation |
| `rejected_rows` | `INTEGER NOT NULL` | Rows that failed validation |
| `clean_affected_rows` | `INTEGER DEFAULT 0` | Clean rows inserted or updated |
| `clean_unchanged_rows` | `INTEGER DEFAULT 0` | Clean rows already present without changes |
| `loaded_at` | `TIMESTAMP DEFAULT CURRENT_TIMESTAMP` | Load timestamp |

### `py_students_upsert_rejected`

Stores rejected source rows and links them to a specific ETL load.

| Column | Type | Purpose |
|---|---|---|
| `rejected_id` | `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY` | Rejected row ID |
| `load_log_id` | `BIGINT` | Link to `py_students_upsert_load_logs.log_id` |
| `external_student_id_raw` | `TEXT` | Raw external student ID from CSV |
| `full_name_raw` | `TEXT` | Raw full name from CSV |
| `email_raw` | `TEXT` | Raw email from CSV |
| `city_raw` | `TEXT` | Raw city from CSV |
| `rejection_reason` | `TEXT NOT NULL` | Reason why the row was rejected |
| `rejected_at` | `TIMESTAMP DEFAULT CURRENT_TIMESTAMP` | Rejection timestamp |

## Foreign Key Integrity

The main ETL script adds a foreign key constraint:

```text
py_students_upsert_rejected.load_log_id
        →
py_students_upsert_load_logs.log_id
```

This means:

- old rejected rows may have `NULL` in `load_log_id`
- new rejected rows are linked to a real load log
- if `load_log_id` is filled, PostgreSQL checks that the referenced `log_id` exists

This protects data integrity and makes rejected rows traceable to a specific ETL run.

## UPSERT and Idempotency

The script uses `ON CONFLICT (external_student_id) DO UPDATE`.

Rows are updated only when data really changed:

```sql
WHERE
    py_students_upsert.full_name IS DISTINCT FROM EXCLUDED.full_name
    OR py_students_upsert.email IS DISTINCT FROM EXCLUDED.email
    OR py_students_upsert.city IS DISTINCT FROM EXCLUDED.city;
```

This makes the load idempotent:

- first run inserts clean rows
- repeated run with the same CSV does not update unchanged rows
- if one clean row changes, only that row is updated

The script tracks this using:

- `clean_affected_rows`
- `clean_unchanged_rows`

## Example Output

Example after running the main ETL script:

```text
Load completed.
Total rows: 9
Valid rows: 6
Rejected rows: 3

Last load logs:
(6, 'students_upsert.csv', 9, 6, 3, 0, 6, datetime.datetime(...))
```

This means:

- 9 rows were read from the CSV file
- 6 rows passed validation
- 3 rows were rejected
- 0 clean rows were inserted or updated during this run
- 6 clean rows were already present and unchanged

## Example Rejected Rows Check

Rejected rows can be checked by load ID:

```sql
SELECT
    rejected_id,
    load_log_id,
    external_student_id_raw,
    full_name_raw,
    email_raw,
    city_raw,
    rejection_reason,
    rejected_at
FROM py_students_upsert_rejected
WHERE load_log_id = 6
ORDER BY rejected_id;
```

Example result:

```text
bad_id  → invalid external_student_id
107     → empty full_name
108     → empty email
```

## Environment Variables

Database credentials are stored in `.env`.

The real `.env` file must not be committed to GitHub. Use `.env.example` as a template:

```text
DB_NAME=online_school_etl
DB_USER=postgres
DB_PASSWORD=your_password_here
DB_HOST=localhost
DB_PORT=5432
```

## Installation

Install dependencies:

```bash
pip install -r requirements.txt
```

## How to Run

From the project root, run the main ETL script:

```bash
python 08_python_postgres_etl/scripts/09_csv_upsert_to_postgres.py
```

To run earlier learning scripts, use the same pattern:

```bash
python 08_python_postgres_etl/scripts/01_db_connection.py
python 08_python_postgres_etl/scripts/08_refactored_etl.py
```

## Requirements

```text
psycopg2-binary
python-dotenv
```

## What This Project Demonstrates

This project demonstrates practical junior-level skills for Data Engineering and ETL work:

- designing PostgreSQL tables
- writing SQL DDL and DML
- using constraints and foreign keys
- importing CSV files
- validating data with Python
- separating clean and rejected rows
- writing ETL load logs
- using UPSERT for repeatable data loads
- checking idempotency with affected/unchanged row counts
- tracking rejected rows by load ID
- using environment variables for database credentials
- organizing Python ETL code into small functions
- using basic type hints

## Current Status

The project is a training repository focused on PostgreSQL and Python ETL fundamentals.

The most complete script is:

```text
08_python_postgres_etl/scripts/09_csv_upsert_to_postgres.py
```

It is the main file to review for the latest ETL logic.
