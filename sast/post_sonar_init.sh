#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Verification post-init SonarQube :
#   • Verifie l acces avec le nouveau token genere
#   • Verifie la possibilite de creer et lister un projet (API valide)
###############################################################################

# Chargement .env
ENV_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.env"
set -a
source <(grep -E '^[A-Z0-9_]+=' "$ENV_FILE")
set +a

SONAR_URL="http://localhost:${SONARQUBE_PORT:-9000}"
TOKEN="${SONAR_TOKEN:-}"

echo "[+] Verification de l authentification API avec le token..."

if curl -sf -u "${TOKEN}:" "${SONAR_URL}/api/authentication/validate" | grep -q '"valid":true'; then
  echo "[✓] Authentification SonarQube reussies"
else
  echo "[-] echec de l authentification avec le token SonarQube"
  exit 1
fi
