import os
import psycopg2
import pytest
from dotenv import load_dotenv
from web.db.hashPassword import hash_password
from web.db.validators import is_valid_email, is_strong_password

# Charger .env
load_dotenv()

# Utilisateurs de test volontairement invalides + un valide
test_users = [
    {"email": "invalid-email", "password": "ValidPass1!"},
    {"email": "john@example.com", "password": "weak"},
    {"email": "jane@example.com", "password": "noSpecial123"},
    {"email": "aliceexample.com", "password": "MissingAt!2024"},
    {"email": "bob@example.com", "password": "12345678"},
    {"email": "valid@example.com", "password": "ValidPass!2024"},  # Valide
]

@pytest.fixture(scope="module")
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

def test_insert_false_users(db_conn):
    cur = db_conn.cursor()

    for user in test_users:
        email = user["email"]
        password = user["password"]

        print(f"\n[~] Test insertion : {email} / {password}")

        if not is_valid_email(email):
            print("[-] Rejete : email invalide")
            continue
        if not is_strong_password(password):
            print("[-] Rejete : mot de passe faible")
            continue

        cur.execute("SELECT id FROM users WHERE email = %s", (email,))
        if cur.fetchone():
            print("[=] Utilisateur deja present")
            continue

        hashed = hash_password(password)
        assert hashed.startswith("$argon2id$")

        cur.execute(
            "INSERT INTO users (email, password) VALUES (%s, %s)",
            (email, hashed)
        )
        db_conn.commit()
        print("[+] Utilisateur insere")

    print("\n--- Contenu de la table users ---")
    cur.execute("SELECT id, email, password FROM users")
    for row in cur.fetchall():
        pwd_mask = "*****" if row[2].startswith("$argon2id$") else row[2]
        print(f"  - ID: {row[0]} | Email: {row[1]} | Password: {pwd_mask}")
    cur.close()
