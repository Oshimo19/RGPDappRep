import os
import psycopg2
import pytest
from dotenv import load_dotenv
from web.db.hashPassword import hash_password

# Charger .env
load_dotenv()

@pytest.fixture
def db_conn():
    conn = psycopg2.connect(
        dbname=os.getenv("PGDATABASE"),
        user=os.getenv("PGUSER"),
        password=os.getenv("PGPASSWORD"),
        host=os.getenv("PGHOSTADDR", "127.0.0.1"),
        port=os.getenv("PGPORT", "5432")
    )
    yield conn
    conn.close()

def test_insert_user(db_conn):
    email = os.getenv("EMAIL_TEST_PYTEST")
    password = os.getenv("PASS_TEST_PYTEST")
    cur = db_conn.cursor()

    cur.execute("SELECT id FROM users WHERE email = %s", (email,))
    exists = cur.fetchone()

    if exists:
        print(f"[-] Utilisateur deja present : {email} (ID: {exists[0]})")
    else:
        hashed = hash_password(password)
        cur.execute(
            "INSERT INTO users (email, password) VALUES (%s, %s)",
            (email, hashed)
        )
        db_conn.commit()
        print("[+] Insertion utilisateur reussie")

    cur.execute("SELECT id, email, '*****', role, createdAt FROM users")
    rows = cur.fetchall()
    for row in rows:
        print(f"  - ID: {row[0]} | Email: {row[1]} | Password: {row[2]} | Role: {row[3]} | CreatedAt: {row[4]}")
    cur.close()
