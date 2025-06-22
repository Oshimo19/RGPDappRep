#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Lancement du scan SonarQube depuis l hote (via image Docker)
#  • Utilise le scanner CLI officiel (sonarsource/sonar-scanner-cli)
#  • Utilise l IP passerelle Docker (172.17.0.1) comme HOST_IP par defaut
#  • Environnement defini via .env
#  • Genere un rapport HTML horodate dans ./sast/reports/
###############################################################################

ENV_FILE="$(dirname "$0")/../.env"
WEB_SRC_DIR="$(realpath "$(dirname "$0")/../web")"
DEFAULT_SONAR_PORT=9000
DOCKER_GATEWAY_IP="172.17.0.1"
REPORTS_DIR="$(dirname "$0")/reports"
mkdir -p "$REPORTS_DIR"

### Fonctions utilitaires ###

load_env() {
  [[ ! -f "$ENV_FILE" ]] && { echo "[~] Fichier .env absent. Creation..."; touch "$ENV_FILE"; }

  while IFS='=' read -r key value; do
    [[ "$key" =~ ^\s*# || -z "$key" ]] && continue
    export "$key"="$(echo "$value" | sed 's/^ *//;s/ *$//')"
  done < <(grep -v '^\s*#' "$ENV_FILE" | grep '=')
}

update_env_var() {
  local var="$1"
  local val="$2"
  if grep -q "^${var}=" "$ENV_FILE"; then
    sed -i "s/^${var}=.*/${var}=${val}/" "$ENV_FILE"
  else
    echo "${var}=${val}" >> "$ENV_FILE"
  fi
  export "$var"="$val"
}

detect_or_force_host_ip() {
  echo "[+] Utilisation de l’IP passerelle Docker : $DOCKER_GATEWAY_IP"
  update_env_var "HOST_IP" "$DOCKER_GATEWAY_IP"
}

validate_env() {
  if [[ -z "${SONAR_TOKEN:-}" ]]; then
    echo "[-] Variable SONAR_TOKEN manquante dans .env"
    exit 1
  fi
}

launch_scan() {
  echo "[+] Lancement du scan SonarQube..."
  docker run --rm \
    --platform linux/amd64 \
    -v "${WEB_SRC_DIR}:/usr/src" \
    sonarsource/sonar-scanner-cli:5.0.1 \
    -Dsonar.projectKey=rgpdapp \
    -Dsonar.projectName=rgpdapp \
    -Dsonar.projectVersion=1.0 \
    -Dsonar.sources=. \
    -Dsonar.sourceEncoding=UTF-8 \
    -Dsonar.host.url="http://${HOST_IP}:${SONARQUBE_PORT:-$DEFAULT_SONAR_PORT}" \
    -Dsonar.login="${SONAR_TOKEN}" \
    "$@"
}

generate_html_report() {
  local now
  now="$(date +'%Y-%m-%d_%H-%M-%S')"
  local report_dir="${REPORTS_DIR}/${now}"
  mkdir -p "$report_dir"
  local json_report="${report_dir}/report.json"
  local html_report="${report_dir}/report.html"

  echo "[+] Telechargement des resultats via l API REST SonarQube..."

  curl -sSf -u "${SONAR_TOKEN}:" \
    "http://${HOST_IP}:${SONARQUBE_PORT:-$DEFAULT_SONAR_PORT}/api/issues/search?componentKeys=rgpdapp&resolved=false&ps=500" \
    -o "$json_report"

  if [[ ! -s "$json_report" ]]; then
    echo "[!] Rapport JSON vide ou echec telechargement"
    return
  fi

  echo "[+] Generation du rapport HTML..."

  {
    echo "<!DOCTYPE html>"
    echo "<html lang='fr'><head><meta charset='UTF-8'>"
    echo "<title>Rapport SAST - ${now}</title>"
    echo "<style>
      body { font-family: Arial, sans-serif; margin: 2em; background: #f9f9f9; color: #222; }
      h1 { color: #005096; }
      ul { list-style: none; padding: 0; }
      li { background: #fff; border-left: 5px solid #ccc; padding: 0.75em 1em; margin: 0.5em 0; box-shadow: 0 1px 3px rgba(0,0,0,0.05); }
      li b { text-transform: uppercase; margin-right: 0.5em; }
      li code { font-family: monospace; color: #555; }
      li:has(b:contains('CRITICAL')) { border-left-color: #d32f2f; }
      li:has(b:contains('MAJOR'))    { border-left-color: #f57c00; }
      li:has(b:contains('MINOR'))    { border-left-color: #fbc02d; }
      li:has(b:contains('INFO'))     { border-left-color: #1976d2; }
    </style></head><body>"
    echo "<h1>Rapport SAST – ${now}</h1><ul>"
    jq -r '.issues[] |
      "<li><b>\(.severity)</b> [\(.type)] <code>\(.component)</code>: \(.message)</li>"' "$json_report"
    echo "</ul></body></html>"
  } > "$html_report"

  echo "[✓] Rapport HTML genere : $html_report"
}

### Main ###

load_env
detect_or_force_host_ip
validate_env
launch_scan "$@"
generate_html_report
