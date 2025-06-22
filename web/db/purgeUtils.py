import os
import psycopg2
from datetime import datetime, timedelta
from dotenv import load_dotenv
import logging

# Initialisation logger
logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

# Charger .env
load_dotenv()

# Fonction de purge des utilisateurs supprimes
def purge_deleted_users(days: int = 30, minutes: int = 0):
    try:
        conn = psycopg2.connect(
            dbname=os.getenv("PGDATABASE"),
            user=os.getenv("PGUSER"),
            password=os.getenv("PGPASSWORD"),
            host=os.getenv("PGHOSTADDR", "127.0.0.1"),
            port=os.getenv("PGPORT", "5432")
        )
        cur = conn.cursor()

        # Calcule la limite de temps (soit en jours, soit en minutes si tests)
        if minutes > 0:
            limit = datetime.now() - timedelta(minutes=minutes)
        else:
            limit = datetime.now() - timedelta(days=days)

        # Supprime les entrées trop anciennes
        cur.execute("DELETE FROM deletedUsers WHERE deletedAt < %s RETURNING email", (limit,))
        deleted = cur.fetchall()
        conn.commit()

        if deleted:
            for email in deleted:
                logger.info(f"[PURGE] Utilisateur definitivement supprime : {email[0]}")
            print(f"[+] Purge complete : {len(deleted)} utilisateur(s) definitivement supprime(s)")
        else:
            print("[-] Aucun utilisateur a purger")

    except Exception as e:
        logger.error(f"[PURGE] Erreur : {e}")
        print(f"[-] Erreur lors de la purge : {e}")

    finally:
        if conn:
            cur.close()
            conn.close()
