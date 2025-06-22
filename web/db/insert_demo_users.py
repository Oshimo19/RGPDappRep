import os
import psycopg2
from dotenv import load_dotenv
from hashPassword import hash_password
from validators import is_valid_email, is_strong_password

# Charger .env
load_dotenv()

# Donnees a inserer
demo_users = [
    {"email": "alice@example.com", "password": "StrongPass-2024", "role": "ADMIN"},
    {"email": "bob@example.com", "password": "UserPass#2024", "role": "USER"},
    {"email": "carol@example.com", "password": "Carol123-pass"},  # pas de role
]

# Connexion BDD
try:
    conn = psycopg2.connect(
        dbname=os.getenv("PGDATABASE"),
        user=os.getenv("PGUSER"),
        password=os.getenv("PGPASSWORD"),
        host=os.getenv("PGHOSTADDR", "127.0.0.1"),
        port=os.getenv("PGPORT", "5432")
    )
    cur = conn.cursor()

    for user in demo_users:
        email = user["email"]
        password = user["password"]
        role = user.get("role", "USER")

        if not is_valid_email(email):
            print(f"[-] Email invalide : {email}")
            continue
        if not is_strong_password(password):
            print(f"[-] Mot de passe faible : {email}")
            continue

        cur.execute("SELECT id FROM users WHERE email = %s", (email,))
        if cur.fetchone():
            print(f"[=] Deja present : {email}")
            continue

        hashed = hash_password(password)
        cur.execute(
            "INSERT INTO users (email, password, role) VALUES (%s, %s, %s)",
            (email, hashed, role)
        )
        print(f"[+] Ajoute : {email}")

    conn.commit()

except Exception as e:
    print(f"[-] Erreur insertion demo : {e}")
    
finally:
    if conn:
        cur.close()
        conn.close()
