import csv
import os
from pathlib import Path

import psycopg2
from dotenv import load_dotenv


BASE_DIR = Path(__file__).resolve().parents[2]
ENV_PATH = BASE_DIR / ".env"
CSV_FILE_PATH = BASE_DIR / "08_python_postgres_etl" / "data" / "students_upsert.csv"

load_dotenv(ENV_PATH)

CleanStudent = tuple[int, str, str, str]
RejectedStudent = tuple[str, str, str, str, str]
LoadLogValues = tuple[str, int, int, int, int, int]


def get_connection():
    return psycopg2.connect(
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT")
    )


def create_tables(cursor) -> None:
    cursor.execute(
        """
        CREATE TABLE IF NOT EXISTS py_students_upsert (
            student_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            external_student_id INTEGER NOT NULL UNIQUE,
            full_name VARCHAR(100) NOT NULL,
            email VARCHAR(100) NOT NULL,
            city VARCHAR(50),
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """
    )

    cursor.execute(
        """
        CREATE TABLE IF NOT EXISTS py_students_upsert_rejected (
            rejected_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            load_log_id BIGINT,
            external_student_id_raw TEXT,
            full_name_raw TEXT,
            email_raw TEXT,
            city_raw TEXT,
            rejection_reason TEXT NOT NULL,
            rejected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """
    )

    cursor.execute(
        """
        CREATE TABLE IF NOT EXISTS py_students_upsert_load_logs (
            log_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            source_file VARCHAR(255) NOT NULL,
            total_rows INTEGER NOT NULL,
            valid_rows INTEGER NOT NULL,
            rejected_rows INTEGER NOT NULL,
            loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """
    )
    

def apply_migrations(cursor) -> None:
    cursor.execute(
        """
        ALTER TABLE py_students_upsert_load_logs
        ADD COLUMN IF NOT EXISTS clean_affected_rows INTEGER DEFAULT 0;
        """
    )

    cursor.execute(
        """
        ALTER TABLE py_students_upsert_load_logs
        ADD COLUMN IF NOT EXISTS clean_unchanged_rows INTEGER DEFAULT 0;
        """
    )

    cursor.execute(
        """
        ALTER TABLE py_students_upsert_rejected
        ADD COLUMN IF NOT EXISTS load_log_id BIGINT;
        """
    )

    cursor.execute(
        """
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT 1
                FROM pg_constraint
                WHERE conname = 'fk_rejected_load_log'
            ) THEN
                ALTER TABLE py_students_upsert_rejected
                ADD CONSTRAINT fk_rejected_load_log
                FOREIGN KEY (load_log_id)
                REFERENCES py_students_upsert_load_logs(log_id);
            END IF;
        END $$;
        """
    )


def read_and_validate_csv(csv_file_path: Path) -> tuple[list[CleanStudent], list[RejectedStudent]]:
    clean_students = []
    rejected_students = []

    with open(csv_file_path, mode="r", encoding="utf-8", newline="") as file:
        reader = csv.DictReader(file)

        for row in reader:
            external_student_id_raw = row.get("external_student_id", "").strip()
            full_name = row.get("full_name", "").strip()
            email = row.get("email", "").strip()
            city = row.get("city", "").strip()

            rejection_reason = None

            try:
                external_student_id = int(external_student_id_raw)
            except ValueError:
                rejection_reason = "invalid external_student_id"

            if rejection_reason is None and not full_name:
                rejection_reason = "empty full_name"

            if rejection_reason is None and not email:
                rejection_reason = "empty email"

            if rejection_reason:
                rejected_students.append(
                    (
                        external_student_id_raw,
                        full_name,
                        email,
                        city,
                        rejection_reason,
                    )
                )
            else:
                clean_students.append(
                    (
                        external_student_id,
                        full_name,
                        email,
                        city,
                    )
                )

    return clean_students, rejected_students


def upsert_clean_students(cursor, clean_students: list[CleanStudent]) -> int:
    upsert_query = """
        INSERT INTO py_students_upsert (
            external_student_id,
            full_name,
            email,
            city
        )
        VALUES (%s, %s, %s, %s)
        ON CONFLICT (external_student_id)
        DO UPDATE SET
            full_name = EXCLUDED.full_name,
            email = EXCLUDED.email,
            city = EXCLUDED.city,
            updated_at = CURRENT_TIMESTAMP
        WHERE
            py_students_upsert.full_name IS DISTINCT FROM EXCLUDED.full_name
            OR py_students_upsert.email IS DISTINCT FROM EXCLUDED.email
            OR py_students_upsert.city IS DISTINCT FROM EXCLUDED.city;
    """

    clean_affected_rows = 0

    for student in clean_students:
        cursor.execute(upsert_query, student)
        clean_affected_rows += cursor.rowcount

    return clean_affected_rows


def insert_load_log(cursor, log_values: LoadLogValues) -> int:
    cursor.execute(
        """
        INSERT INTO py_students_upsert_load_logs (
            source_file,
            total_rows,
            valid_rows,
            rejected_rows,
            clean_affected_rows,
            clean_unchanged_rows
        )
        VALUES (%s, %s, %s, %s, %s, %s)
        RETURNING log_id;
        """,
        log_values
    )

    return cursor.fetchone()[0]


def insert_rejected_students(
    cursor, 
    rejected_students: list[RejectedStudent], 
    load_log_id: int
) -> None:
    if not rejected_students:
        return

    rejected_students_with_log_id = [
        (load_log_id, *student)
        for student in rejected_students
    ]

    cursor.executemany(
        """
        INSERT INTO py_students_upsert_rejected (
            load_log_id,
            external_student_id_raw,
            full_name_raw,
            email_raw,
            city_raw,
            rejection_reason
        )
        VALUES (%s, %s, %s, %s, %s, %s);
        """,
        rejected_students_with_log_id
    )


def load_data(
    cursor, 
    clean_students: list[CleanStudent], 
    rejected_students: list[RejectedStudent], 
    source_file: str
) -> None:
    clean_affected_rows = upsert_clean_students(cursor, clean_students)

    total_rows = len(clean_students) + len(rejected_students)
    valid_rows = len(clean_students)
    rejected_rows = len(rejected_students)
    clean_unchanged_rows = valid_rows - clean_affected_rows

    log_values = (
        source_file,
        total_rows,
        valid_rows,
        rejected_rows,
        clean_affected_rows,
        clean_unchanged_rows,
    )

    load_log_id = insert_load_log(cursor, log_values)

    insert_rejected_students(cursor, rejected_students, load_log_id)


def print_load_logs(cursor) -> None:
    cursor.execute(
        """
        SELECT
            log_id,
            source_file,
            total_rows,
            valid_rows,
            rejected_rows,
            clean_affected_rows,
            clean_unchanged_rows,
            loaded_at
        FROM py_students_upsert_load_logs
        ORDER BY log_id DESC
        LIMIT 5;
        """
    )

    rows = cursor.fetchall()

    print("\nLast load logs:")
    for row in rows:
        print(row)


def main() -> None:
    connection = None
    cursor = None

    try:
        connection = get_connection()
        cursor = connection.cursor()

        create_tables(cursor)
        apply_migrations(cursor)

        clean_students, rejected_students = read_and_validate_csv(CSV_FILE_PATH)

        load_data(
            cursor=cursor,
            clean_students=clean_students,
            rejected_students=rejected_students,
            source_file=CSV_FILE_PATH.name,
        )

        connection.commit()

        print("Load completed.")
        print("Total rows:", len(clean_students) + len(rejected_students))
        print("Valid rows:", len(clean_students))
        print("Rejected rows:", len(rejected_students))

        print_load_logs(cursor)

    except Exception as error:
        if connection:
            connection.rollback()
        print("Error:", error)

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


if __name__ == "__main__":
    main()