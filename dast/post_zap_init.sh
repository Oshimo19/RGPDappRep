#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Verification post-init OWASP ZAP (mode daemon dans Docker)
#   • Verifie que l'API REST repond sans cle API via docker exec
#   • Recupere et affiche la version
###############################################################################

ENV_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.env"

# Chargement .env
set -a
source <(grep -E '^[A-Z0-9_]+=' "$ENV_FILE")
set +a

ZAP_CONTAINER="rgpd_zap"
ZAP_INTERNAL_PORT=8080
ZAP_API_ENDPOINT="http://localhost:${ZAP_INTERNAL_PORT}/JSON/core/view/version/"

echo "[+] Verification post-init OWASP ZAP dans le conteneur '${ZAP_CONTAINER}'..."

for i in {1..20}; do
  if docker ps --format '{{.Names}}' | grep -q "^${ZAP_CONTAINER}$"; then
    RESPONSE=$(docker exec -i "${ZAP_CONTAINER}" curl -s -m 3 "${ZAP_API_ENDPOINT}" || true)
    if [[ -n "$RESPONSE" && "$RESPONSE" != *"ZAP Error"* ]]; then
      VERSION=$(echo "$RESPONSE" | grep -oP '"version"\s*:\s*"\K[^"]+')
      echo "[✓] ZAP repond — version : ${VERSION}"
      exit 0
    fi
  else
    echo "[-] Conteneur '${ZAP_CONTAINER}' non trouve ou arrete"
    exit 1
  fi

  echo "[~] Attente de reponse ZAP (${i}/20)..."
  sleep 3
done

echo "[-] Echec : ZAP ne repond pas via l'API REST apres 20 tentatives"
exit 1
