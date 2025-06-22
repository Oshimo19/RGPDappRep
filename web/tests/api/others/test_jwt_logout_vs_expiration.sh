#!/bin/bash

# Configuration
BASE_URL="http:/localhost:5000"
EMAIL_TEST="test@demo.fr"
PASS_TEST="Secure123!Test"
COOKIE_FILE=$(mktemp)

# Localisation du projet
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(realpath "$SCRIPT_DIR/../../../../")"

# Export PYTHONPATH
export PYTHONPATH="$PROJECT_ROOT"

# Selection de l interpreteur Python
PYTHON_BIN="$PROJECT_ROOT/.venv/bin/python"
if [ ! -x "$PYTHON_BIN" ]; then
  PYTHON_BIN=$(which python3)
fi

# Lancement de l application Flask avec verification
echo "[+] Demarrage de l'application Flask..."
cd "$PROJECT_ROOT" || exit 1
"$PYTHON_BIN" -c "import web.app" 2>/dev/null || {
  echo "[ERREUR] Le module 'web.app' est introuvable. Verifiez PYTHONPATH."
  exit 1
}
"$PYTHON_BIN" -m web.app &
SERVER_PID=$!
sleep 2

# 1. Connexion initiale
echo "[+] Connexion utilisateur (1ere session)..."
curl -s -c "$COOKIE_FILE" -X POST "$BASE_URL/api/login" -d "email=$EMAIL&password=$PASSWORD" > /dev/null
TOKEN1=$(grep session_token "$COOKIE_FILE" | awk '{print $NF}')

# 2. Acces USER autorise
echo "[+] Verification acces USER AVANT deconnexion..."
curl -s -b "$COOKIE_FILE" -o /dev/null -w " ↳ Status: %{http_code}\n" "$BASE_URL/api/user/dashboard"

# 3. Deconnexion
echo "[+] Deconnexion..."
curl -s -b "$COOKIE_FILE" -c "$COOKIE_FILE" -X POST "$BASE_URL/api/logout" > /dev/null

# 4. Verification d acces apres deconnexion
echo "[+] Verification acces USER APRES deconnexion..."
curl -s -b "$COOKIE_FILE" -o /dev/null -w " ↳ Status: %{http_code}\n" "$BASE_URL/api/user/dashboard"

# 5. Connexion nouvelle session
echo "[+] Connexion utilisateur (2e session)..."
curl -s -c "$COOKIE_FILE" -X POST "$BASE_URL/api/login" -d "email=$EMAIL&password=$PASSWORD" > /dev/null
TOKEN2=$(grep session_token "$COOKIE_FILE" | awk '{print $NF}')

# 6. Verification acces USER
echo "[+] Verification acces USER AVANT expiration..."
curl -s -b "$COOKIE_FILE" -o /dev/null -w " ↳ Status: %{http_code}\n" "$BASE_URL/api/user/dashboard"

# 7. Attente pour expiration simulee (configurable)
EXPIRE_SECONDS=65
echo "[+] Attente $EXPIRE_SECONDS s pour simuler expiration..."
sleep $EXPIRE_SECONDS

# 8. Acces avec token possiblement expire
echo "[+] Verification acces USER APRES expiration..."
curl -s -H "Authorization: Bearer $TOKEN2" -o /dev/null -w " ↳ Status: %{http_code}\n" "$BASE_URL/api/user/dashboard"

# 9. Verification de l entropie des tokens
if [[ "$TOKEN1" != "$TOKEN2" ]]; then
  echo "[✓] Entropie : les tokens sont differents"
else
  echo "[✗] Alerte : les tokens sont identiques (manque d alea ?)"
fi

# Nettoyage
echo "[+] Arret du serveur Flask..."
kill "$SERVER_PID"
rm "$COOKIE_FILE"

echo "[✓] Test termine."
