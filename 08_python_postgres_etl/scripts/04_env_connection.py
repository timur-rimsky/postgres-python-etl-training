import os
from pathlib import Path

import psycopg2
from dotenv import load_dotenv


connection = None
cursor = None

BASE_DIR = Path(__file__).resolve().parents[2]
ENV_PATH = BASE_DIR / ".env"

load_dotenv(ENV_PATH)

try:
    connection = psycopg2.connect(
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT")
    )

    cursor = connection.cursor()

    cursor.execute("SELECT CURRENT_DATE;")
    result = cursor.fetchone()

    print("Connected to PostgreSQL using .env")
    print("Current date from database:", result[0])

except Exception as error:
    print("Database error:")
    print(error)

finally:
    if cursor is not None:
        cursor.close()

    if connection is not None:
        connection.close()