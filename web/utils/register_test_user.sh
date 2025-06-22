#!/bin/bash

# =============================================================================
# Enregistrement automatique de l utilisateur de test
# Compatible avec app.py et app_2_3.py
# Ce script charge automatiquement .env si necessaire
# =============================================================================

[ "$_RGPDAPP_REGISTER_ALREADY_RUN" = "1" ] && return 0
export _RGPDAPP_REGISTER_ALREADY_RUN=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(realpath "$SCRIPT_DIR/../..")"
ENV_FILE="$PROJECT_ROOT/.env"

# Si les variables essentielles ne sont pas definies, on charge .env
if [ -z "$EMAIL_TEST" ] || [ -z "$PASS_TEST" ]; then
    if [ -f "$ENV_FILE" ]; then
        set -a
        source "$ENV_FILE"
        set +a
    else
        echo "[-] Erreur : .env introuvable pour charger EMAIL_TEST et PASS_TEST"
        exit 1
    fi
fi

# Verification finale
if [ -z "$EMAIL_TEST" ] || [ -z "$PASS_TEST" ]; then
    echo "[-] Erreur : EMAIL_TEST ou PASS_TEST non defini meme après chargement .env"
    exit 1
fi

# BASE_URL doit etre defini (ou on utilise un defaut)
BASE_URL="${BASE_URL:-http://localhost:5000}"
REGISTER_URL="${BASE_URL}/api/register"

echo "[~] Verification de la presence de l'utilisateur de test ($EMAIL_TEST) sur : $REGISTER_URL"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$REGISTER_URL" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "email=${EMAIL_TEST}&password=${PASS_TEST}")

if [ "$HTTP_CODE" = "201" ]; then
    echo "[+] Utilisateur $EMAIL_TEST enregistre avec succès"
elif [ "$HTTP_CODE" = "409" ] || [ "$HTTP_CODE" = "400" ]; then
    echo "[i] Utilisateur $EMAIL_TEST deja existant"
else
    echo "[-] Erreur lors de l enregistrement (HTTP $HTTP_CODE)"
    echo "    Verifiez que /api/register est fonctionnel"
fi
