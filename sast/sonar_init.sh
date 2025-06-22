#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Initialisation SonarQube : changement du mot de passe admin + creation token
# -----------------------------------------------------------------------------
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"

# Charger .env si necessaire
if [[ -f "$ENV_FILE" ]]; then
  set -a
  source <(grep -E '^[A-Z0-9_]+=' "$ENV_FILE")
  set +a
fi

SONAR_PORT="${SONARQUBE_PORT:-9000}"
SONAR_HOST="http://localhost:${SONAR_PORT}"

# 1. Attente disponibilite de l API SonarQube
echo "[~] Verification de la disponibilite de SonarQube..."
for i in {1..30}; do
  if curl -sf "${SONAR_HOST}/api/system/status" | grep -q '"status":"UP"'; then
    echo "[✓] SonarQube operationnel"
    break
  fi
  echo "[~] Attente SonarQube ($i/30)"
  sleep 5
done

# 2. Mot de passe admin aleatoire
NEW_PWD="Adm$(openssl rand -hex 6)"
echo "[+] Changement du mot de passe admin..."

resp=$(curl -s -o /dev/null -w "%{http_code}" -u admin:admin -X POST \
  "${SONAR_HOST}/api/users/change_password" \
  -d "login=admin&previousPassword=admin&password=${NEW_PWD}")

if [[ "$resp" != "204" ]]; then
  echo "[-] echec du changement de mot de passe (HTTP $resp)"
  exit 1
fi

# 3. Generation d’un token API
TOKEN_NAME="rgpd_token_$(date +%s)"
echo "[+] Generation du token API SonarQube..."

TOKEN=$(curl -s -u "admin:${NEW_PWD}" -X POST \
  "${SONAR_HOST}/api/user_tokens/generate" -d "name=${TOKEN_NAME}" \
  | jq -r '.token')

if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
  echo "[-] echec de la generation du token"
  exit 1
fi

echo "[✓] Token genere : ${TOKEN_NAME}"

# 4. Mise a jour du .env
echo "[+] Mise a jour du fichier .env..."

chmod 600 "$ENV_FILE"
grep -q "^SONAR_TOKEN=" "$ENV_FILE" && \
  sed -i "s/^SONAR_TOKEN=.*/SONAR_TOKEN=${TOKEN}/" "$ENV_FILE" || \
  echo "SONAR_TOKEN=${TOKEN}" >> "$ENV_FILE"

grep -q "^ADMIN_PASSWORD_SONAR=" "$ENV_FILE" && \
  sed -i "s/^ADMIN_PASSWORD_SONAR=.*/ADMIN_PASSWORD_SONAR=${NEW_PWD}/" "$ENV_FILE" || \
  echo "ADMIN_PASSWORD_SONAR=${NEW_PWD}" >> "$ENV_FILE"

echo "[✓] .env mis a jour"

echo "[✓] Initialisation SonarQube terminee."
