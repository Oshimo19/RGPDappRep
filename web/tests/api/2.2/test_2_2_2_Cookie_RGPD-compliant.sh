#!/bin/bash

# RGPD Test 2.2.2 – Cookie securise (HttpOnly, SameSite, expiration, unicite)
# Version sans fichier COOKIE_FILE : extraction manuelle des tokens.

# ─────────────────────────────────────────────────────────────
# Chargement de la config + demarrage Flask
# ─────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(realpath "$SCRIPT_DIR/../../../..")"
LOAD_SCRIPT="${PROJECT_ROOT}/web/load_env_conf.sh"
REGISTER_SCRIPT="${PROJECT_ROOT}/web/utils/register_test_user.sh"

if [ ! -f "$LOAD_SCRIPT" ]; then
    echo "[-] Erreur : $LOAD_SCRIPT introuvable"
    exit 1
fi

echo "[~] Chargement de la configuration et demarrage de Flask..."
source "$LOAD_SCRIPT" start web.app
sleep 2    # petite marge

# ─────────────────────────────────────────────────────────────
# Register utilisateur de test (si absent)
# ─────────────────────────────────────────────────────────────
echo "[~] Enregistrement utilisateur test (si necessaire)..."
if [ -x "$REGISTER_SCRIPT" ]; then
    "$REGISTER_SCRIPT"
else
    echo "[-] Script $REGISTER_SCRIPT manquant ou non executable"
fi

# ─────────────────────────────────────────────────────────────
# Session 1 : login
# ─────────────────────────────────────────────────────────────
echo "[~] Connexion utilisateur (session 1)…"
RESPONSE1=$(curl -s -D - -X POST "$BASE_URL/api/login" \
  -d "email=$EMAIL_TEST" -d "password=$PASS_TEST")

COOKIE_LINE1=$(echo "$RESPONSE1" | grep -i "Set-Cookie:")
echo "[i] Attributs du cookie reçu :"
echo " $COOKIE_LINE1"
echo

# Verif attributs RGPD
echo "[~] Verification conformite RGPD :"
echo "$COOKIE_LINE1" | grep -q "HttpOnly"        && echo " [+] HttpOnly present"            || echo " [-] HttpOnly manquant"
# echo "$COOKIE_LINE" | grep -q "Secure"        && echo "  [+] Secure present"            || echo "  [-] Secure manquant"
echo "$COOKIE_LINE1" | grep -q "SameSite=Strict" && echo " [+] SameSite=Strict present"     || echo " [-] SameSite manquant"
echo "$COOKIE_LINE1" | grep -q "Max-Age="        && echo " [+] Expiration automatique"      || echo " [-] Expiration manquante"
echo "$COOKIE_LINE1" | grep -q "Path=/"          && echo " [+] Path=/ correct"              || echo " [-] Path manquant"
echo "$COOKIE_LINE1" | grep -q "session_token="  && echo " [+] Nom du cookie OK"            || echo " [-] Cookie absent"
echo

# Extraction token 1
TOKEN1=$(echo "$COOKIE_LINE1" | grep -o 'session_token=[^;]*' | cut -d '=' -f2)
echo "[i] Token1 : ${TOKEN1} (len=${#TOKEN1})"
echo

# Acces avant logout
echo "[~] Acces dashboard avant logout…"
STATUS_BEFORE=$(curl -s -H "Cookie: session_token=$TOKEN1" -o /dev/null -w "%{http_code}" "$BASE_URL/api/user/dashboard")
[ "$STATUS_BEFORE" = "200" ] && echo " [+] Acces autorise (200)" || echo " [-] echec acces (code $STATUS_BEFORE)"
echo

# Deconnexion
echo "[~] Deconnexion (cookie JWT session_token revoque cote serveur)…"
curl -s -X POST -H "Cookie: session_token=$TOKEN1" "$BASE_URL/api/logout" > /dev/null

# Attente pour s'assurer que le middleware recharge la blacklist (optionnel)
sleep 1

# Acces apres logout
echo "[~] Acees apres logout (doit etre refuse)…"
STATUS_AFTER=$(curl -s -H "Cookie: session_token=$TOKEN1" -o /dev/null -w "%{http_code}" "$BASE_URL/api/user/dashboard")
[ "$STATUS_AFTER" = "403" ] && echo " [+] Refus (403)" || echo " [-] Acces non bloque (code $STATUS_AFTER)"
echo

# ─────────────────────────────────────────────────────────────
# Session 2 : login, puis attente d’expiration
# ───────────────────────────────────────────────────────────── 
echo "[~] Connexion utilisateur (session 2)…"
RESPONSE2=$(curl -s -D - -X POST "$BASE_URL/api/login" \
  -d "email=$EMAIL_TEST" -d "password=$PASS_TEST")
COOKIE_LINE2=$(echo "$RESPONSE2" | grep -i "Set-Cookie:")
TOKEN2=$(echo "$COOKIE_LINE2" | grep -o 'session_token=[^;]*' | cut -d '=' -f2)

EXPIRE_SECONDS=$((JWT_EXPIRATION + 5))
echo "[~] Attente $EXPIRE_SECONDS s (expiration max = $JWT_EXPIRATION s)…"
sleep $EXPIRE_SECONDS

echo "[~] Acces apres expiration…"
STATUS_EXP=$(curl -s -H "Cookie: session_token=$TOKEN2" -o /dev/null -w "%{http_code}" "$BASE_URL/api/user/dashboard")
[ "$STATUS_EXP" = "403" ] && echo " [+] Refus apres expiration (403)" || echo " [-] Encore actif (code $STATUS_EXP)"
echo

# Verif unicite
echo "[~] Verification unicite :"
echo "  Token1 : $TOKEN1"
echo "  Token2 : $TOKEN2"
[ "$TOKEN1" != "$TOKEN2" ] && echo " [+] Tokens differents (OK)" || echo " [-] Tokens identiques (KO)"
echo

# Nettoyage
echo "[+] Arret de Flask…"
source "$LOAD_SCRIPT" stop
echo "[✓] Test RGPD 2.2.2 termine."
