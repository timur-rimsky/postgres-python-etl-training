# PostgreSQL and Python ETL Training

Training project focused on junior-level Data Engineering and ETL development with Python, SQL and PostgreSQL.

The project demonstrates how raw CSV data can be read, validated, split into clean and rejected records, loaded into PostgreSQL, tracked with load logs and processed in a repeatable way without creating duplicate records.

## Main Focus

The main goal of this project is to practice practical ETL and PostgreSQL skills:

* PostgreSQL table design
* SQL DDL and DML operations
* constraints and relational integrity
* CSV data loading
* Python connection to PostgreSQL
* data validation with Python
* clean/rejected data flow
* UPSERT with `ON CONFLICT`
* idempotent loading
* load logs
* rejected rows tracking
* transaction handling with `commit()` and `rollback()`

## Technologies Used

* Python
* PostgreSQL
* SQL
* psycopg2
* python-dotenv
* CSV files

## Project Structure

```text
postgres-python-etl-training/
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

## SQL Training Blocks

The `sql/` folder contains PostgreSQL practice files.

| File                         | Topic                              |
| ---------------------------- | ---------------------------------- |
| `01_create_tables.sql`       | Basic table creation               |
| `02_insert_data.sql`         | Insert operations                  |
| `03_queries.sql`             | Basic SQL queries                  |
| `04_postgres_features.sql`   | PostgreSQL-specific features       |
| `05_copy_import.sql`         | CSV import with `COPY` / `\copy`   |
| `06_staging_import.sql`      | Staging table import flow          |
| `07_relations.sql`           | Relations and foreign keys         |
| `08_indexes_explain.sql`     | Indexes and `EXPLAIN`              |
| `09_order_by_indexes.sql`    | Indexes for sorting and `ORDER BY` |
| `10_indexes_insert_cost.sql` | Insert cost of indexes             |
| `11_upsert_on_conflict.sql`  | UPSERT with `ON CONFLICT`          |

## Python ETL Training Blocks

The Python scripts are located in:

```text
08_python_postgres_etl/scripts/
```

| File                           | Description                                                                   |
| ------------------------------ | ----------------------------------------------------------------------------- |
| `01_db_connection.py`          | Checks Python connection to PostgreSQL                                        |
| `02_create_insert_read.py`     | Creates a table, inserts rows and reads data back                             |
| `03_transaction_rollback.py`   | Demonstrates transaction rollback                                             |
| `04_env_connection.py`         | Connects to PostgreSQL using environment variables                            |
| `05_executemany_insert.py`     | Inserts multiple rows using `executemany()`                                   |
| `06_csv_to_postgres.py`        | Reads a clean CSV file and loads it into PostgreSQL                           |
| `07_csv_validation.py`         | Validates raw CSV data and separates clean/rejected rows                      |
| `08_refactored_etl.py`         | Refactored ETL script with functions, clean rows, rejected rows and logs      |
| `09_csv_upsert_to_postgres.py` | Main ETL script with validation, UPSERT, load logs and rejected rows tracking |

## Main ETL Script

The main script is:

```text
08_python_postgres_etl/scripts/09_csv_upsert_to_postgres.py
```

It implements a CSV to PostgreSQL ETL process:

```text
students_upsert.csv
        ↓
Python CSV reader
        ↓
row validation
        ↓
valid rows                    invalid rows
        ↓                           ↓
py_students_upsert            py_students_upsert_rejected
        ↓                           ↓
UPSERT logic                  linked to load_log_id
        ↓                           ↓
py_students_upsert_load_logs
```

## Validation Rules

A row is considered valid if:

* `external_student_id` can be converted to an integer
* `full_name` is not empty
* `email` is not empty

Rejected rows are saved with a rejection reason:

* `invalid external_student_id`
* `empty full_name`
* `empty email`

## Database Tables Used by the Main ETL Script

### `py_students_upsert`

Stores clean student records.

Main fields:

* `student_id`
* `external_student_id`
* `full_name`
* `email`
* `city`
* `updated_at`

`external_student_id` is used as a business key for UPSERT logic.

### `py_students_upsert_rejected`

Stores rejected source rows.

Main fields:

* `rejected_id`
* `load_log_id`
* `external_student_id_raw`
* `full_name_raw`
* `email_raw`
* `city_raw`
* `rejection_reason`
* `rejected_at`

Rejected rows keep raw values and rejection reasons, so invalid source data is not lost silently.

### `py_students_upsert_load_logs`

Stores one row per ETL load.

Main fields:

* `log_id`
* `source_file`
* `total_rows`
* `valid_rows`
* `rejected_rows`
* `clean_affected_rows`
* `clean_unchanged_rows`
* `loaded_at`

This table helps track how many rows were processed, loaded, rejected or left unchanged.

## Key Engineering Decisions

* `external_student_id` is used as a business key for UPSERT logic.
* Clean and rejected rows are stored separately.
* Rejected rows keep raw values and rejection reasons.
* Each ETL run is tracked in a load log table.
* `IS DISTINCT FROM` prevents unnecessary updates when incoming data has not changed.
* The load runs inside one transaction to avoid partial writes.
* Rejected rows are linked to load logs with a foreign key.

## UPSERT and Idempotency

The script uses:

```sql
ON CONFLICT (external_student_id) DO UPDATE
```

Rows are updated only when data really changed:

```sql
WHERE
    py_students_upsert.full_name IS DISTINCT FROM EXCLUDED.full_name
    OR py_students_upsert.email IS DISTINCT FROM EXCLUDED.email
    OR py_students_upsert.city IS DISTINCT FROM EXCLUDED.city;
```

This makes the load idempotent:

* first run inserts clean rows;
* repeated run with the same CSV does not create duplicates;
* unchanged rows are not updated again;
* changed rows are updated only when needed.

The script tracks this using:

* `clean_affected_rows`
* `clean_unchanged_rows`

## How to Check Idempotency

1. Run the main ETL script once.
2. Run the same script again with the same CSV file.
3. Check the latest load log.
4. The second run should have:

   * no duplicate rows in `py_students_upsert`;
   * `clean_affected_rows = 0`;
   * `clean_unchanged_rows = valid_rows`.

## Example Output

Example after running the main ETL script:

```text
Load completed.
Total rows: 9
Valid rows: 6
Rejected rows: 3
```

Example load log:

```text
source_file: students_upsert.csv
total_rows: 9
valid_rows: 6
rejected_rows: 3
clean_affected_rows: 0
clean_unchanged_rows: 6
```

This means that the file was processed successfully, invalid rows were saved separately, and clean rows were already present without changes.

## Environment Variables

Database credentials are stored in `.env`.

The real `.env` file must not be committed to GitHub. Use `.env.example` as a template:

```env
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

From the project root, run:

```bash
python 08_python_postgres_etl/scripts/09_csv_upsert_to_postgres.py
```

## Requirements

```text
psycopg2-binary
python-dotenv
```

## What This Project Demonstrates

This project demonstrates practical junior-level skills for ETL and Data Engineering work:

* designing PostgreSQL tables;
* writing SQL DDL and DML;
* using constraints and foreign keys;
* importing CSV files;
* validating data with Python;
* separating clean and rejected rows;
* writing ETL load logs;
* using UPSERT for repeatable data loads;
* checking idempotency with affected/unchanged row counts;
* tracking rejected rows by load ID;
* using environment variables for database credentials;
* organizing Python ETL code into small functions;
* handling transactions with `commit()` and `rollback()`.

## Current Status

This is a training project focused on PostgreSQL and Python ETL fundamentals.

The most complete script is:

```text
08_python_postgres_etl/scripts/09_csv_upsert_to_postgres.py
```

It is the main file to review for the latest ETL logic.
