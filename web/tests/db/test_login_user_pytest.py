import os
import psycopg2
import pytest
from dotenv import load_dotenv
from web.db.hashPassword import verify_password

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

def test_login_user(db_conn):
    email = os.getenv("EMAIL_TEST_PYTEST")
    password = os.getenv("PASS_TEST_PYTEST")
    cur = db_conn.cursor()
    cur.execute("SELECT password FROM users WHERE email = %s", (email,))
    row = cur.fetchone()
    cur.close()

    assert row and verify_password(row[0], password), "[-] Connexion echouee"
    print(f"[+] Connexion reussie pour {email}")
