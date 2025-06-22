#!/bin/bash
set -euo pipefail

echo "[*] Reinitialisation de la BDD PostgreSQL (conteneur rgpd_postgres)..."

cd "$(dirname "$0")" || exit 1

# Chargement du fichier .env a la racine
ENV_FILE="../../.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "[!] Fichier .env introuvable a $ENV_FILE"
    exit 1
fi

# Chargement propre des variables
set -a
source "$ENV_FILE"
set +a

# Verification des variables essentielles
if [[ -z "${PGUSER:-}" || -z "${PGPASSWORD:-}" ]]; then
    echo "[!] Variables PGUSER ou PGPASSWORD manquantes dans .env"
    exit 1
fi

# Execution SQL via Docker
echo "[*] Creation des tables via init_db.sql..."
psql -U "$PGUSER" -d "$PGDATABASE" < init_db.sql || {
    echo "[!] Erreur lors de l'initialisation des tables"
    exit 1
}

# Insertion des utilisateurs de demo via script Python (depuis hote)
echo "[*] Insertion des utilisateurs de test..."
PYTHONPATH=.. python3 insert_demo_users.py && \
    echo "[✓] BDD reinitialisee avec succes" || \
    echo "[!] echec lors de l'insertion des utilisateurs"
