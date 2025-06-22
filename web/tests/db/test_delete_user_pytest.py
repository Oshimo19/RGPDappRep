import os
import psycopg2
import pytest
from dotenv import load_dotenv

# Charger .env
load_dotenv()

@pytest.mark.parametrize("confirm", ["o"])
def test_delete_user(monkeypatch, confirm):
    email = os.getenv("EMAIL_TEST_PYTEST")
    admin_id = int(os.getenv("ADMIN_ID", "1"))
    self_delete = os.getenv("SELF_DELETE", "true").lower() == "true"

    monkeypatch.setattr("builtins.input", lambda _: confirm)

    conn = None
    try:
        conn = psycopg2.connect(
            dbname=os.getenv("PGDATABASE"),
            user=os.getenv("PGUSER"),
            password=os.getenv("PGPASSWORD"),
            host=os.getenv("PGHOSTADDR", "127.0.0.1"),
            port=os.getenv("PGPORT", "5432")
        )
        cur = conn.cursor()

        cur.execute("SELECT id FROM users WHERE email = %s", (email,))
        user = cur.fetchone()
        assert user, f"Utilisateur {email} introuvable dans users."

        user_id = user[0]
        deleted_by = user_id if self_delete else admin_id

        cur.execute("SELECT id FROM deletedUsers WHERE email = %s", (email,))
        already_deleted = cur.fetchone()
        if already_deleted:
            pytest.skip(f"Utilisateur {email} deja dans deletedUsers.")
        else:
            cur.execute(
                "INSERT INTO deletedUsers (email, deletedBy) VALUES (%s, %s)",
                (email, deleted_by)
            )
            cur.execute("DELETE FROM users WHERE id = %s", (user_id,))
            conn.commit()

        # Verifie que l utilisateur n existe plus dans users
        cur.execute("SELECT id FROM users WHERE id = %s", (user_id,))
        assert cur.fetchone() is None, "L utilisateur n a pas ete supprime de users"

        # Verifie qu il est bien dans deletedUsers
        cur.execute("SELECT email FROM deletedUsers WHERE email = %s", (email,))
        assert cur.fetchone(), "L utilisateur n est pas archive dans deletedUsers"

        cur.close()

    except Exception as e:
        pytest.fail(f"Erreur inattendue : {e}")
    finally:
        if conn:
            conn.close()
