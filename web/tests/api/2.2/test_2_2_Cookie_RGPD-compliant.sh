#!/bin/bash

# RGPD Test 2.2 – Verification des attributs RGPD du cookie session_token

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(realpath "$SCRIPT_DIR/../../../..")"
LOAD_SCRIPT="${PROJECT_ROOT}/web/load_env_conf.sh"
REGISTER_SCRIPT="${PROJECT_ROOT}/web/utils/register_test_user.sh"

echo "[~] Chargement de la configuration et demarrage de Flask..."
source "$LOAD_SCRIPT" start web.app
sleep 2

COOKIE_FILE=$(mktemp)
BASE_URL="$BASE_URL"

echo "[~] Enregistrement utilisateur test (si necessaire)..."
BASE_URL="$BASE_URL" "$REGISTER_SCRIPT"

### Connexion 1 – Extraction du cookie ###
echo "[~] Connexion utilisateur (session 1)…"
LOGIN_OUTPUT=$(curl -s -D - -c "$COOKIE_FILE" -X POST "$BASE_URL/api/login" \
  -d "email=$EMAIL_TEST&password=$PASS_TEST")

COOKIE_LINE=$(echo "$LOGIN_OUTPUT" | grep -i "Set-Cookie:")
echo "[i] Attributs du cookie reçu :"
echo "    $COOKIE_LINE"
echo

echo "[~] Verification conformite RGPD :"
echo "$COOKIE_LINE" | grep -q "HttpOnly"        && echo "  [+] HttpOnly present"            || echo "  [-] HttpOnly manquant"
# echo "$COOKIE_LINE" | grep -q "Secure"        && echo "  [+] Secure present"            || echo "  [-] Secure manquant"
echo "$COOKIE_LINE" | grep -q "SameSite=Strict" && echo "  [+] SameSite=Strict present"     || echo "  [-] SameSite manquant"
echo "$COOKIE_LINE" | grep -q "Max-Age="        && echo "  [+] Expiration automatique"       || echo "  [-] Expiration manquante"
echo "$COOKIE_LINE" | grep -q "Path=/"          && echo "  [+] Portee du cookie : Path=/ OK" || echo "  [-] Path manquant"
echo "$COOKIE_LINE" | grep -q "session_token="  && echo "  [+] Nom du cookie correct"        || echo "  [-] Cookie absent"

### Acces avec cookie valide ###
echo "[~] Acces avant logout (devrait etre autorise)…"
STATUS_BEFORE=$(curl -s -b "$COOKIE_FILE" -o /dev/null -w "%{http_code}" "$BASE_URL/api/user/dashboard")
[ "$STATUS_BEFORE" = "200" ] && echo "  [+] Acces autorise (200)" || echo "  [-] Acces refuse"

### Recuperation Token 1 ###
TOKEN1=$(grep session_token "$COOKIE_FILE" | awk '{print $NF}')

### Deconnexion ###
echo "[~] Deconnexion (cookie JWT session_token revoque cote serveur)…"
curl -s -b "$COOKIE_FILE" -c "$COOKIE_FILE" -X POST "$BASE_URL/api/logout" > /dev/null

### Acces apres logout ###
echo "[~] Acces apres logout (doit etre refuse)…"
STATUS_AFTER=$(curl -s -b "$COOKIE_FILE" -o /dev/null -w "%{http_code}" "$BASE_URL/api/user/dashboard")
[ "$STATUS_AFTER" = "403" ] && echo "  [+] Refus (403)" || echo "  [-] Acces non bloque (code $STATUS_AFTER)"

### Nouvelle session ###
echo "[~] Connexion utilisateur (session 2)…"
rm "$COOKIE_FILE"
COOKIE_FILE=$(mktemp)
curl -s -c "$COOKIE_FILE" -X POST "$BASE_URL/api/login" \
  -d "email=$EMAIL_TEST&password=$PASS_TEST" > /dev/null

### Expiration ###
EXPIRE_SECONDS=65
echo "[~] Attente $EXPIRE_SECONDS s (expiration max = 60 s)…"
sleep $EXPIRE_SECONDS

TOKEN2=$(grep session_token "$COOKIE_FILE" | awk '{print $NF}')
PAYLOAD=$(echo "$TOKEN2" | cut -d '.' -f2 | base64 -d 2>/dev/null)
echo "[DEBUG] Payload JWT expire : $PAYLOAD"

echo "[~] Acces apres expiration…"
STATUS_EXPIRED=$(curl -s -H "Authorization: Bearer $TOKEN2" -o /dev/null -w "%{http_code}" "$BASE_URL/api/user/dashboard")
[ "$STATUS_EXPIRED" = "403" ] && echo "  [+] Refus apres expiration (403)" || echo "  [-] Acces encore actif apres expiration"

### Verification unicite (jti) ###
echo "[~] Verification unicite :"
echo "  Token1 : $TOKEN1"
echo "  Token2 : $TOKEN2"
[ "$TOKEN1" != "$TOKEN2" ] && echo "  [+] Tokens differents (OK)" || echo "  [-] Token identique entre sessions"

### Nettoyage ###
echo "[+] Arret de Flask..."
source "$LOAD_SCRIPT" stop
rm "$COOKIE_FILE"

echo "[✓] Test RGPD 2.2.2 termine."
