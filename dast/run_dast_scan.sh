#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Lancement du scan OWASP ZAP (headless via API REST)
#  • Verifie que ZAP est pret via post_zap_init.sh
#  • Lance un spider + scan actif sur le backend Flask
#  • Genere un rapport HTML + JSON horodate dans ./dast/reports/
###############################################################################

ENV_FILE="$(dirname "$0")/../.env"
POST_CHECK_SCRIPT="$(dirname "$0")/post_zap_init.sh"
REPORTS_DIR="$(dirname "$0")/reports"
LOAD_SCRIPT="$(dirname "$0")/../web/load_env_conf.sh"
mkdir -p "$REPORTS_DIR"

ZAP_CONTAINER="rgpd_zap"
ZAP_PORT_INTERNAL=8080
TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"

### Chargement .env ###
load_env() {
  [[ ! -f "$ENV_FILE" ]] && { echo "[~] Fichier .env absent. Creation..."; touch "$ENV_FILE"; }

  while IFS='=' read -r key value; do
    [[ "$key" =~ ^\s*# || -z "$key" ]] && continue
    export "$key"="$(echo "$value" | sed 's/^ *//;s/ *$//')"
  done < <(grep -v '^\s*#' "$ENV_FILE" | grep '=')
}

### Demande du module Flask + start ###
start_flask_from_choice() {
  if [[ ! -f "$LOAD_SCRIPT" ]]; then
    echo "[-] Script de démarrage Flask manquant : $LOAD_SCRIPT"
    exit 1
  fi

  source "$LOAD_SCRIPT"

  echo "[?] Choisir l'application Flask à scanner :"
  echo "    1. web.app      (cookies RGPD - 2.2)"
  echo "    2. web.app_2_3  (JWT frontend - 2.3)"
  read -rp "[>] Choix (1 ou 2) : " choix

  if [[ "$choix" == "2" ]]; then
    FLASK_MODULE="web.app_2_3"
    TARGET_URL="http://${HOST_IP}:${FLASK_PORT_2}"
  else
    FLASK_MODULE="web.app"
    TARGET_URL="http://${HOST_IP}:${FLASK_PORT}"
  fi

  echo "[~] Lancement de Flask avec $FLASK_MODULE..."
  start_flask "$FLASK_MODULE"
}

### Vérification du service ZAP ###
check_zap_ready() {
  echo "[+] Verification de ZAP via ${POST_CHECK_SCRIPT}..."
  bash "$POST_CHECK_SCRIPT"
}

### Lancement du scan actif ###
launch_zap_scan() {
  echo "[+] Cible : ${TARGET_URL}"

  local encoded_url
  encoded_url=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${TARGET_URL}', safe=''))")

  echo "[+] Spider en cours..."
  docker exec -i "${ZAP_CONTAINER}" curl -s \
    "http://localhost:${ZAP_PORT_INTERNAL}/JSON/spider/action/scan/?url=${encoded_url}" >/dev/null
  sleep 5

  echo "[+] Scan actif en cours..."
  docker exec -i "${ZAP_CONTAINER}" curl -s \
    "http://localhost:${ZAP_PORT_INTERNAL}/JSON/ascan/action/scan/?url=${encoded_url}" >/dev/null

  while true; do
    local progress
    progress=$(docker exec -i "${ZAP_CONTAINER}" curl -s \
      "http://localhost:${ZAP_PORT_INTERNAL}/JSON/ascan/view/status/" | jq -r '.status')
    echo -ne "\r[~] Progression scan actif : ${progress}%"
    [[ "$progress" == "100" ]] && break
    sleep 5
  done
  echo ""
}

### Génération du rapport ###
generate_report() {
  local report_dir="${REPORTS_DIR}/${TIMESTAMP}"
  mkdir -p "$report_dir"

  local report_html="${report_dir}/report.html"
  local report_json="${report_dir}/report.json"

  echo "[+] Génération du rapport ZAP..."

  docker exec -i "${ZAP_CONTAINER}" curl -s \
    "http://localhost:${ZAP_PORT_INTERNAL}/OTHER/core/other/htmlreport/" > "$report_html"

  docker exec -i "${ZAP_CONTAINER}" curl -s \
    "http://localhost:${ZAP_PORT_INTERNAL}/OTHER/core/other/jsonreport/" > "$report_json"

  echo "[✓] Rapport HTML généré : $report_html"
  echo "[✓] Rapport JSON généré : $report_json"
}

### Nettoyage ###
cleanup() {
  echo "[~] Arrêt de Flask..."
  stop_flask || true
}

### Main ###
load_env
start_flask_from_choice
check_zap_ready
launch_zap_scan
generate_report
cleanup
