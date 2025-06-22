#!/bin/bash

# =============================================================================
# Chargement securise de la configuration (.env + config.py)
# Utilisable dans les scripts de test automatises (start/stop Flask)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(realpath "$SCRIPT_DIR/..")"
ENV_FILE="$PROJECT_ROOT/.env"
CONFIG_PY="$PROJECT_ROOT/web/config.py"

# Verifie la presence des fichiers requis
if [ ! -f "$ENV_FILE" ]; then
    echo "[-] Erreur : fichier .env introuvable a la racine ($ENV_FILE)"
    exit 1
fi

if [ ! -f "$CONFIG_PY" ]; then
    echo "[-] Erreur : config.py manquant dans $PROJECT_ROOT/"
    exit 1
fi

# Chargement des variables d'environnement
set -a
source "$ENV_FILE"
set +a

# Valeurs par defaut si non definies
FLASK_PORT="${FLASK_PORT:-5000}"
FLASK_PORT_2="${FLASK_PORT_2:-5001}"

BASE_URL="${BASE_URL:-http://localhost:$FLASK_PORT}"
BASE_URL_2="${BASE_URL_2:-http://localhost:$FLASK_PORT_2}"
export BASE_URL BASE_URL_2

# Binaire Python
PYTHON_BIN="$PROJECT_ROOT/.venv/bin/python"
if [ ! -x "$PYTHON_BIN" ]; then
    PYTHON_BIN=$(which python3)
fi

# =============================================================================
# Fonctions utilitaires
# =============================================================================

start_flask() {
    local app_module="$1"  # ex: web.app ou web.app_2_3

    echo "[+] Demarrage de Flask ($app_module)..."
    cd "$PROJECT_ROOT" || { echo "[-] Erreur : impossible d'acceder a $PROJECT_ROOT"; exit 1; }
    export PYTHONPATH="$PROJECT_ROOT"

    # Choix du port en fonction du module
    if [[ "$app_module" == "web.app_2_3" ]]; then
        DETECTED_PORT="$FLASK_PORT_2"
    else
        DETECTED_PORT="$FLASK_PORT"
    fi

    export FLASK_PORT="$DETECTED_PORT"
    export BASE_URL="http://localhost:$DETECTED_PORT"

    # Demarrage
    "$PYTHON_BIN" -m "$app_module" > /tmp/flask_stdout.log 2>&1 &
    FLASK_PID=$!
    echo "$FLASK_PID" > /tmp/flask_pid_rgpd
    echo "[i] PID Flask : $FLASK_PID"

    # Attente de disponibilite
    for i in {1..10}; do
        if curl -s -o /dev/null "$BASE_URL"; then
            echo "[+] Flask repond sur le port $DETECTED_PORT"
            echo "[DEBUG] BASE_URL : $BASE_URL"
            return
        fi
        sleep 0.5
    done

    echo "[-] Erreur : Flask ne repond pas sur $BASE_URL"
    echo "=== stdout de Flask ==="
    cat /tmp/flask_stdout.log
    exit 1
}

stop_flask() {
    if [ -f /tmp/flask_pid_rgpd ]; then
        FLASK_PID=$(cat /tmp/flask_pid_rgpd)
        echo "[+] Arret du serveur Flask (PID $FLASK_PID)..."
        kill "$FLASK_PID" >/dev/null 2>&1
        rm /tmp/flask_pid_rgpd
    else
        echo "[!] Aucun PID Flask a arreter (/tmp/flask_pid_rgpd absent)"
    fi
}

start_postgres() {
    echo "[+] PostgreSQL : a demarrer manuellement si necessaire (systemctl ou docker)"
}

stop_postgres() {
    echo "[+] PostgreSQL : a arreter manuellement si necessaire"
}

# =============================================================================
# Commandes principales
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "$1" in
    start)
      start_flask "$2"
      ;;
    stop)
      stop_flask
      ;;
    *)
      echo "Usage : $0 {start|stop} [module_flask]"
      ;;
  esac
fi