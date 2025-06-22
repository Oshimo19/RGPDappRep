#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Verifie que l'instance SonarQube ne contient plus de projets
###############################################################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"

# Charger le port depuis .env
if [[ -f "$ENV_FILE" ]]; then
  export $(grep SONARQUBE_PORT "$ENV_FILE" | xargs)
fi

SONAR_PORT="${SONARQUBE_PORT:-9000}"
SONAR_URL="http://localhost:${SONAR_PORT}"

echo "[~] Verification post-purge sur ${SONAR_URL}"

# Attente courte de disponibilite (en cas de restart apres purge)
for i in {1..15}; do
  STATUS=$(curl -s "${SONAR_URL}/api/system/status" | jq -r .status || echo "DOWN")
  [[ "$STATUS" == "UP" ]] && break
  echo "[~] Attente SonarQube UP ($i/15)..."
  sleep 3
done

# Recuperer la liste des projets
TOTAL=$(curl -s "${SONAR_URL}/api/projects/search" | jq '.paging.total // 0')

if [[ "$TOTAL" == "0" ]]; then
  echo "[✓] Aucun projet present dans SonarQube (purge confirmee)"
else
  echo "[-] ${TOTAL} projet(s) encore present(s) dans SonarQube"
  exit 1
fi
