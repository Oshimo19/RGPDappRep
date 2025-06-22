#!/bin/bash

echo "[*] Affichage du contenu des tables PostgreSQL..."

# Se placer dans le dossier du script
cd "$(dirname "$0")" || exit 1

# Charger .env
ENV_FILE="../../.env"
if [[ -f "$ENV_FILE" ]]; then
    while IFS='=' read -r key value; do
        [[ "$key" =~ ^\s*# || -z "$key" ]] && continue
        export "$key"="$(echo "$value" | sed 's/^ *//;s/ *$//')"
    done < "$ENV_FILE"
else
    echo "[!] Fichier .env introuvable à $ENV_FILE"
    exit 1
fi

# Creer un fichier SQL temporaire
TMP_SQL=$(mktemp)
cat <<EOF > "$TMP_SQL"
\\echo '--- Table users ---'
SELECT id, email, '*****' AS password, role, createdAt FROM users;

\\echo ''
\\echo '--- Table deletedUsers ---'
SELECT id, email, deletedBy, deletedAt FROM deletedUsers;
EOF

# Executer le script SQL
psql -U "$PGUSER" -h "$PGHOSTADDR" -p "$PGPORT" -d "$PGDATABASE" -f "$TMP_SQL"

if [ $? -eq 0 ]; then
    echo "[+] Tables affichees avec succes"
else
    echo "[!] Erreur lors de l affichage des tables"
fi

# Supprimer le fichier temporaire
rm "$TMP_SQL"
