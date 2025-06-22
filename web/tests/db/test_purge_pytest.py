import sys
import os
import psycopg2
import pytest
from dotenv import load_dotenv
from pathlib import Path

# Ajouter le dossier projet (racine RGPDapp) au PYTHONPATH
PROJECT_ROOT = Path(__file__).resolve().parents[1]  # = dossier /web
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from web.db.purgeUtils import purge_deleted_users

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

def test_purge_deleted_users(db_conn):
    print("[*] Purge des utilisateurs supprimes depuis plus de 2 minutes...")
    purge_deleted_users(minutes=2)

    cur = db_conn.cursor()
    cur.execute("SELECT id, email, deletedBy, deletedAt FROM deletedUsers")
    rows = cur.fetchall()
    cur.close()

    if not rows:
        print("  [-] Table vide")
    else:
        for row in rows:
            print(f"  - ID: {row[0]} | Email: {row[1]} | Supprime par ID: {row[2]} | Date: {row[3]}")
