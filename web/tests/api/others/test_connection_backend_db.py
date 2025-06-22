import psycopg2
import os
import pytest
from dotenv import load_dotenv

# Charger .env
load_dotenv()

def test_index_route(client):
    """
    Verifie que Flask repond correctement à la route "/".
    """
    response = client.get("/")
    assert response.status_code == 200

    data = response.get_json()
    assert data is not None
    assert "message" in data
    assert "Bonjour" in data["message"]

def test_postgres_connection():
    """
    Verifie que la base PostgreSQL est joignable et repond.
    """
    try:
        conn = psycopg2.connect(
            dbname=os.getenv("PGDATABASE"),
            user=os.getenv("PGUSER"),
            password=os.getenv("PGPASSWORD"),
            host=os.getenv("PGHOSTADDR"),
            port=os.getenv("PGPORT", "5432")
        )
        with conn.cursor() as cur:
            cur.execute("SELECT 1;")
            assert cur.fetchone()[0] == 1
        conn.close()
    except Exception as e:
        pytest.fail(f"Connexion BDD echouee : {e}")
