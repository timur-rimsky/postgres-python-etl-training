# PostgreSQL Training and Python ETL Practice

This repository contains my PostgreSQL and Python ETL training project.

The goal of this project is to practice core Data Engineering skills:

* PostgreSQL table design
* SQL queries and joins
* constraints and data integrity
* CSV import
* staging / clean / rejected data flow
* Python connection to PostgreSQL
* CSV validation with Python
* ETL logging
* transaction handling with `commit()` and `rollback()`

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
│   └── 07_relations.sql
│
├── 08_python_postgres_etl/
│   ├── data/
│   │   ├── students.csv
│   │   └── raw_students.csv
│   │
│   └── scripts/
│       ├── 01_db_connection.py
│       ├── 02_create_insert_read.py
│       ├── 03_transaction_rollback.py
│       ├── 04_env_connection.py
│       ├── 05_executemany_insert.py
│       ├── 06_csv_to_postgres.py
│       ├── 07_csv_validation.py
│       └── 08_refactored_etl.py
│
├── .env.example
├── .gitignore
├── requirements.txt
└── README.md
```

## Technologies Used

* Python
* PostgreSQL
* SQL
* psycopg2
* python-dotenv
* CSV files

## SQL Training Blocks

The `sql/` folder contains PostgreSQL practice files.

### Main topics covered

* table creation
* `PRIMARY KEY`
* `FOREIGN KEY`
* `UNIQUE`
* `CHECK`
* `DEFAULT`
* `IDENTITY`
* `COPY` / `\copy`
* staging tables
* clean and rejected records
* load logs
* joins
* aggregations
* `HAVING`
* window functions
* many-to-many relationships

## Python ETL Block

The main Python ETL practice is located in:

```text
08_python_postgres_etl/scripts/
```

### Script overview

| File                         | Description                                              |
| ---------------------------- | -------------------------------------------------------- |
| `01_db_connection.py`        | Checks Python connection to PostgreSQL                   |
| `02_create_insert_read.py`   | Creates a table, inserts rows, reads data back           |
| `03_transaction_rollback.py` | Demonstrates transaction rollback after a failed insert  |
| `04_env_connection.py`       | Connects to PostgreSQL using environment variables       |
| `05_executemany_insert.py`   | Inserts multiple rows using `executemany()`              |
| `06_csv_to_postgres.py`      | Reads a clean CSV file and loads it into PostgreSQL      |
| `07_csv_validation.py`       | Validates raw CSV data and separates clean/rejected rows |
| `08_refactored_etl.py`       | Final refactored ETL script with functions               |

## Final ETL Script

The main script is:

```text
08_python_postgres_etl/scripts/08_refactored_etl.py
```

It performs the following ETL process:

```text
raw_students.csv
        ↓
Python CSV reading
        ↓
data validation
        ↓
valid rows → py_clean_students
invalid rows → py_rejected_students
        ↓
load result → py_load_logs
```

## Validation Rules

A row is considered valid if:

* `full_name` is not empty
* `age` is a valid integer
* `age > 0`
* `city` is not empty

Rejected rows are saved with a rejection reason:

* `invalid age`
* `missing required field`

## Database Tables Created by Final ETL

The final ETL script creates three PostgreSQL tables:

### `py_clean_students`

Stores valid student records.

| Column       | Type                 |
| ------------ | -------------------- |
| `student_id` | identity primary key |
| `full_name`  | text                 |
| `age`        | integer              |
| `city`       | text                 |
| `created_at` | timestamp            |

### `py_rejected_students`

Stores rejected records with a reason.

| Column          | Type                 |
| --------------- | -------------------- |
| `rejected_id`   | identity primary key |
| `full_name`     | text                 |
| `age`           | text                 |
| `city`          | text                 |
| `reject_reason` | text                 |

### `py_load_logs`

Stores ETL load statistics.

| Column           | Type                 |
| ---------------- | -------------------- |
| `load_id`        | identity primary key |
| `source_file`    | text                 |
| `total_raw_rows` | integer              |
| `valid_rows`     | integer              |
| `rejected_rows`  | integer              |
| `loaded_at`      | timestamp            |

## Example ETL Output

When running the final ETL script, the expected output is:

```text
Tables created.
Valid rows: 2
Rejected rows: 3
ETL load completed.
(1, 'raw_students.csv', 5, 2, 3, datetime.datetime(...))
```

This means:

* 5 rows were read from the raw CSV file
* 2 rows were valid
* 3 rows were rejected
* the load result was written to the log table

## Environment Variables

Database credentials are stored in `.env`.

The real `.env` file is not committed to GitHub.

Create your own `.env` file based on `.env.example`:

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

## How to Run the Final ETL Script

From the project root, run:

```bash
python 08_python_postgres_etl/scripts/08_refactored_etl.py
```

## Requirements

The project requires:

```text
psycopg2-binary
python-dotenv
```

## What I Practiced

During this project, I practiced:

* writing PostgreSQL DDL and DML queries
* creating relational schemas
* using constraints to protect data quality
* importing CSV data
* separating raw, clean, and rejected data
* connecting Python to PostgreSQL
* using environment variables for database credentials
* inserting data with `executemany()`
* using transactions with `commit()` and `rollback()`
* refactoring ETL logic into functions

## Notes

This is a training project created as part of my Data Engineering learning path.

The main focus is not on building a production-ready system, but on practicing core PostgreSQL and Python ETL concepts in a clear and reproducible way.
