#!/bin/bash

# RGPD Test 2.3.2 – Verifie que le token JWT est utilisable et transferable cote frontend (localStorage)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(realpath "$SCRIPT_DIR/../../../..")"
LOAD_SCRIPT="${PROJECT_ROOT}/web/load_env_conf.sh"
REGISTER_SCRIPT="${PROJECT_ROOT}/web/utils/register_test_user.sh"

echo "[~] Chargement configuration et lancement Flask sur port $FLASK_PORT_2..."
source "$LOAD_SCRIPT" start web.app_2_3
sleep 2

BASE_URL="http://localhost:$FLASK_PORT_2"
COOKIE_FILE=$(mktemp)

echo "[~] Enregistrement utilisateur test (si necessaire)..."
BASE_URL="$BASE_URL" "$REGISTER_SCRIPT"

echo "[+] Connexion utilisateur via /api/login-json (retour JSON + token)..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/login-json" \
  -d "email=$EMAIL_TEST&password=$PASS_TEST" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -c "$COOKIE_FILE")

JWT=$(echo "$LOGIN_RESPONSE" | jq -r '.token')

if [[ -z "$JWT" || "$JWT" == "null" ]]; then
  echo "[-] Erreur : aucun JWT recu depuis /api/login-json"
  source "$LOAD_SCRIPT" stop
  rm "$COOKIE_FILE"
  exit 1
fi

echo "[i] JWT recu (header.payload) :"
echo "$JWT" | cut -d'.' -f1-2
echo "[i] Payload decode :"
echo "$JWT" | cut -d'.' -f2 | base64 -d 2>/dev/null
echo

echo "[+] Simulation frontend : envoi du token via Authorization: Bearer"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $JWT" "$BASE_URL/api/user/dashboard")

if [[ "$STATUS" == "200" ]]; then
  echo "[+] Token utilisable depuis le frontend (HTTP 200 recu)"
  echo "[+] Ce token peut etre stocke côte client (ex: localStorage) si XSS/CSRF maitrise."
else
  echo "[-] Token refuse côte serveur (HTTP $STATUS)"
  echo "[-] Non conforme pour stockage frontend"
fi

echo "[+] Arret de Flask..."
source "$LOAD_SCRIPT" stop
rm "$COOKIE_FILE"

echo "[✓] Test RGPD 2.3.2 termine."
