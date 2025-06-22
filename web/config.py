"""
Configuration centralisee (chargée en tout début d execution).
Respecte OWASP 2021, RGPD, et principes SOLID : aucune valeur sensible
ni magique dispersee dans le code.
"""
import os
from dotenv import load_dotenv

# ───────────────────────────────────────────
# Chargement des variables d environnement
# ───────────────────────────────────────────
load_dotenv()                     # lit le fichier .env s’il existe

# ───────────────────────────────────────────
# Cle secrete Flask & JWT
# ───────────────────────────────────────────
SECRET_KEY = os.getenv("SECRET_KEY", "dev-secret-change-me")

# ───────────────────────────────────────────
# Base de donnees PostgreSQL
# ───────────────────────────────────────────
DB_CONFIG = {
    "dbname":  os.getenv("PGDATABASE"),
    "user":    os.getenv("PGUSER"),
    "password": os.getenv("PGPASSWORD"),
    "host":    os.getenv("PGHOSTADDR", "127.0.0.1"),
    "port":    os.getenv("PGPORT", "5432"),
}

# ───────────────────────────────────────────
# Brute-force / JWT
# ───────────────────────────────────────────
BRUTEFORCE_MAX_ATTEMPTS   = int(os.getenv("BRUTEFORCE_MAX", 5))
BRUTEFORCE_BLOCK_DURATION = int(os.getenv("BRUTEFORCE_DURATION", 300))   # secondes

JWT_EXPIRATION_SECONDS = int(os.getenv("JWT_EXPIRATION", 60))            # secondes
JWT_ALGORITHM          = "HS256"

# ───────────────────────────────────────────
# Cookie de session securise
# ───────────────────────────────────────────
COOKIE_NAME      = "session_token"
COOKIE_SECURE    = os.getenv("COOKIE_SECURE", "false").lower() == "true"   # True en prod HTTPS
COOKIE_SAMESITE  = os.getenv("COOKIE_SAMESITE", "Strict")                  # 'Lax' au besoin

COOKIE_CONFIG = {
    "name"     : COOKIE_NAME,
    "httponly" : True,
    "secure"   : COOKIE_SECURE,
    "samesite" : COOKIE_SAMESITE,
    "max_age"  : JWT_EXPIRATION_SECONDS,
    "path"     : "/",
}

# ───────────────────────────────────────────
# En-têtes de securite HTTP (OWASP Secure Headers)
# ───────────────────────────────────────────
SECURITY_HEADERS = {
    "Content-Security-Policy":
        "default-src 'self'; "
        "script-src 'self'; "
        "style-src 'self'; "
        "object-src 'none'; "
        "base-uri 'none'; "
        "frame-ancestors 'none'; "
        "form-action 'self';",
    "X-Frame-Options": "DENY",
    "X-Content-Type-Options": "nosniff",
    "Referrer-Policy": "no-referrer",
    "Permissions-Policy": "geolocation=(), microphone=(), camera=(), payment=(), usb=(), bluetooth=()",
    # HSTS (sera utile dès que HTTPS activé)
    "Strict-Transport-Security": "max-age=63072000; includeSubDomains; preload",
}

# ───────────────────────────────────────────
# Gestion des erreurs & logs
# ───────────────────────────────────────────
HTTP_ERROR_CODES = [400, 403, 404, 500]

LOG_FILE  = os.getenv("LOG_FILE", "web.log")
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
