#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------------------------------
# Purge SonarQube : Purge complete de SonarQube : conteneur, volume, scans et rapports (--full)
#   • par defaut : purge du dossier scans/ (rapide)
#   • --full     : suppression du conteneur, du volume et du dossier scans
# --------------------------------------------------------------------

FULL_PURGE=false
if [[ "${1:-}" == "--full" ]]; then
  FULL_PURGE=true
fi

echo "[!] Purge de SonarQube (conteneur + base + scans)..."

if $FULL_PURGE; then
  # 1) Tente d'arreter SonarQube (meme s'il n'est pas lance)
  docker compose stop sonarqube   >/dev/null 2>&1 || true
  docker compose rm -f sonarqube  >/dev/null 2>&1 || true

  # 2) Supprimer le volume PostgreSQL (si possible)
  if docker volume rm rgpdapp_pgdata; then
    echo "[✓] Volume rgpdapp_pgdata supprime"
  else
    echo "[-] Volume rgpdapp_pgdata toujours en cours d'utilisation."
    echo "    → Execute : docker compose down -v && docker compose down"
    exit 1
  fi
fi

# 3) Nettoyage du dossier scans/
SCAN_DIR="$(dirname "$0")/scans"
rm -rf "$SCAN_DIR"
mkdir -p "$SCAN_DIR"
echo "[✓] Dossier scans purge"

echo "[✓] Purge SonarQube terminee."
