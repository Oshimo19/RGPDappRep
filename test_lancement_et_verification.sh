#!/usr/bin/env bash
set -euo pipefail

echo "[+] Verification de l environnement Docker RGPDapp..."

### CONFIG ###
# BACKEND_NAME="rgpd_backend"
# POSTGRES_NAME="rgpd_postgres"
SONAR_NAME="rgpd_sonarqube"
ZAP_NAME="rgpd_zap"

# BACKEND_PORT="${FLASK_PORT:-5000}"
SONAR_PORT="${SONARQUBE_PORT:-9000}"
ZAP_PORT="${ZAP_PORT:-8080}"

### 1. Docker disponible ###
command -v docker >/dev/null || {
  echo "[-] Docker est manquant. → https://docs.docker.com/get-docker/"
  exit 1
}
command -v docker compose >/dev/null || {
  echo "[-] Docker Compose v2 est manquant. → https://docs.docker.com/compose/install/linux/"
  exit 1
}
docker info >/dev/null || {
  echo "[-] Le demon Docker n est pas actif."
  exit 1
}

### 2. Arret des conteneurs RGPDapp si deja lances ###
if docker ps --format '{{.Names}}' | grep -q '^rgpd_'; then
  echo "[!] Conteneurs RGPDapp deja en cours — arret..."
  docker compose down -v || true
  docker compose down || true
fi

### 3. Build & lancement ###
echo "[+] Lancement des services RGPDapp..."
if ! docker compose up -d --build; then
  echo "[-] Erreur au lancement des conteneurs."
  docker compose logs --tail=30
  exit 1
fi

### 4. Affichage initial ###
echo "[~] Services en cours de demarrage..."
sleep 5
docker compose ps

### 5. Attente de la sante des services ###
wait_for_health() {
  local name=$1
  echo "[~] Attente de sante pour : $name"

  has_healthcheck=$(docker inspect --format='{{if .State.Health}}yes{{else}}no{{end}}' "$name" 2>/dev/null || echo "no")

  if [[ "$has_healthcheck" == "yes" ]]; then
    for i in {1..20}; do
      status=$(docker inspect --format='{{.State.Health.Status}}' "$name" 2>/dev/null || echo "absent")
      if [[ "$status" == "healthy" ]]; then
        echo "[✓] $name : healthy"
        return 0
      fi
      echo "[~] $name : $status ($i/20)"
      sleep 3
    done
    echo "[-] Timeout sante : $name"
    return 1
  else
    echo "[~] Aucun healthcheck defini pour $name → skip (HTTP check plus tard)"
  fi
}

# wait_for_health "$POSTGRES_NAME"
# wait_for_health "$BACKEND_NAME"
wait_for_health "$ZAP_NAME"
echo "[~] Saut du healthcheck Docker pour $SONAR_NAME → verif HTTP directe..."

### 6. Verification HTTP des services exposes ###
check_http_service() {
  local url=$1
  local name=$2
  local expected=${3:-200}
  for i in {1..10}; do
    if [[ "$name" == "SonarQube" ]]; then
      raw=$(curl -s "$url")
      if echo "$raw" | grep -q '"status":"UP"'; then
        echo "[✓] $name OK (status: UP) sur $url"
        return 0
      fi
      echo "[~] $name non disponible (status non UP) — tentative $i/10"
      sleep 2
    else
      code=$(curl -s -o /dev/null -w "%{http_code}" "$url")
      if [[ "$code" == "$expected" ]]; then
        echo "[✓] $name OK sur $url"
        return 0
      fi
      echo "[~] $name non disponible (HTTP $code) — tentative $i/10"
      sleep 2
    fi
  done
  echo "[-] $name indisponible apres 10 tentatives"
  echo "[!] Reponse brute depuis $url :"
  curl -s "$url" || true
  return 1
}

echo "[+] Verification HTTP des services exposes..."
# check_http_service "http://localhost:$BACKEND_PORT" "Backend Flask"
check_http_service "http://localhost:$SONAR_PORT/api/system/status" "SonarQube"
check_http_service "http://localhost:$ZAP_PORT" "ZAP"

### 7. Test connexion backend ↔ PostgreSQL ###
# echo "[+] Test backend ↔ PostgreSQL via pytest..."
# docker compose exec -T "$BACKEND_NAME" \
#  pytest web/tests/api/others/test_connection_backend_db.py -q --disable-warnings || {
#    echo "[-] Test de connexion echoue"
#    exit 1
#  }

### 8. Fin ###
echo "[✓] L environnement Docker RGPDapp est pret."
