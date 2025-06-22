#!/bin/bash

# RGPD Test 2.3.1 – Verifie la generation + signature du JWT côte backend

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(realpath "$SCRIPT_DIR/../../../..")"
LOAD_SCRIPT="${PROJECT_ROOT}/web/load_env_conf.sh"
REGISTER_SCRIPT="${PROJECT_ROOT}/web/utils/register_test_user.sh"

echo "[~] Chargement configuration et lancement Flask app_2_3..."
source "$LOAD_SCRIPT" start web.app_2_3
sleep 2

BASE_URL="$BASE_URL_2"
COOKIE_FILE=$(mktemp)

echo "[~] Enregistrement utilisateur test (si necessaire)..."
BASE_URL="$BASE_URL" "$REGISTER_SCRIPT"

echo "[+] Connexion utilisateur via /api/login-json pour obtenir un JWT..."
RESPONSE=$(curl -s -c "$COOKIE_FILE" -X POST "$BASE_URL/api/login-json" \
  -d "email=$EMAIL_TEST&password=$PASS_TEST" \
  -H "Content-Type: application/x-www-form-urlencoded")

echo "[DEBUG] Reponse brute : $RESPONSE"
JWT=$(echo "$RESPONSE" | jq -r '.token')

if [[ -z "$JWT" || "$JWT" == "null" ]]; then
  echo "[-] echec : aucun token JWT reçu depuis /api/login-json"
  source "$LOAD_SCRIPT" stop
  rm "$COOKIE_FILE"
  exit 1
fi

echo "[+] Analyse du JWT reçu..."
IFS='.' read -r HEADER PAYLOAD SIGNATURE <<< "$JWT"

if [[ -z "$HEADER" || -z "$PAYLOAD" || -z "$SIGNATURE" ]]; then
  echo "[-] JWT mal forme : structure invalide"
  source "$LOAD_SCRIPT" stop
  rm "$COOKIE_FILE"
  exit 1
fi

echo "[+] JWT structure OK (header.payload.signature)"
echo " Header    : $HEADER"
echo " Payload   : $PAYLOAD"
echo " Signature : $SIGNATURE"

echo "[i] Payload decode (base64) :"
echo "$PAYLOAD" | base64 -d 2>/dev/null || echo "[!] Erreur de decodage base64"
echo

echo "[+] Test d'acces protege via Authorization: Bearer..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $JWT" "$BASE_URL/api/user/dashboard")

if [[ "$STATUS" == "200" ]]; then
  echo "[+] Acces autorise avec JWT signe"
else
  echo "[-] echec d'acces avec JWT (HTTP $STATUS)"
fi

echo "[+] Arret de Flask..."
source "$LOAD_SCRIPT" stop
rm "$COOKIE_FILE"

echo "[✓] Test RGPD 2.3.1 termine."
