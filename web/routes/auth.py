import os
import logging
import psycopg2
import time
from flask import Blueprint, request, jsonify, make_response, current_app
from web.db.hashPassword import hash_password, verify_password
from web.db.validators import is_valid_email, is_strong_password
from web.middlewares.jwt import jwt_middleware

auth_routes = Blueprint("auth", __name__, url_prefix="/api")

# Logger
logger = logging.getLogger(__name__)

# Middlewares
# jwt_middleware = JWTMiddleware()

# Connexion BDD
def get_conn():
    return psycopg2.connect(
        dbname=os.getenv("PGDATABASE"),
        user=os.getenv("PGUSER"),
        password=os.getenv("PGPASSWORD"),
        host=os.getenv("PGHOSTADDR", "127.0.0.1"),
        port=os.getenv("PGPORT", "5432")
    )

# Routes
@auth_routes.route("/register", methods=["POST"])
def register():
    email = getattr(request, "cleaned_email", "")
    password = getattr(request, "cleaned_password", "")
    
    if not is_valid_email(email):
        return jsonify({"error": "Email invalide"}), 400
    if not is_strong_password(password):
        return jsonify({"error": "Mot de passe trop faible"}), 400

    hashed = hash_password(password)

    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("INSERT INTO users (email, password, role) VALUES (%s, %s, %s)", (email, hashed, "USER"))
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({"message": "Inscription reussie"}), 201
    except Exception as e:
        logger.warning(f"[REGISTER] Erreur insertion utilisateur : {str(e)}")
        return jsonify({"error": "Email deja utilise ou erreur interne"}), 400

@auth_routes.route("/login", methods=["POST"])
def login():
    email = getattr(request, "cleaned_email", "")
    password = getattr(request, "cleaned_password", "")

    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("SELECT id, password, role FROM users WHERE email = %s", (email,))
        row = cur.fetchone()
        cur.close()
        conn.close()
    except Exception as e:
        logger.error(f"[LOGIN] Erreur SQL : {str(e)}")
        return jsonify({"error": "Erreur serveur"}), 500

    if not row or not verify_password(row[1], password):
        return jsonify({"error": "Echec de connexion"}), 401

    user_id, _, role = row
    token = jwt_middleware.generateToken(user_id, email, role)

    cfg = current_app.config.get("COOKIE_CONFIG", {})
    resp = make_response(jsonify({"message": "Connexion reussie"}))
    resp.set_cookie(
        cfg.get("name", "session_token"),
        value=token,
        httponly=cfg.get("httponly", True),
        secure=cfg.get("secure", False),
        samesite=cfg.get("samesite", "Strict"),
        max_age=cfg.get("max_age", 900),    # 900 s = 15 min
        expires=int(time.time()) + cfg.get("max_age", 900), # 900 s = 15 min
        path=cfg.get("path", "/")
    )
    return resp


@auth_routes.route("/logout", methods=["POST"])
def logout():
    cfg = current_app.config.get("COOKIE_CONFIG", {})
    token = None

    # 1. Chercher le token JWT : header Authorization > cookie
    auth_header = request.headers.get("Authorization", "")
    if auth_header.startswith("Bearer "):
        token = auth_header.split(" ", 1)[1]
    else:
        token = request.cookies.get(cfg.get("name", "session_token"))

    # 2. Revoquer cote serveur
    if token:
        logger.info("[Logout] Token reçu pour revocation")
        jwt_middleware.revoke_token(token)
    else:
        logger.info("[Logout] Aucun token fourni dans la requête")

    # 3. Repondre + invalider le cookie cote client
    resp = make_response(jsonify({"message": "Deconnexion reussie"}))
    resp.set_cookie(
        cfg.get("name", "session_token"),
        value="",
        httponly=cfg.get("httponly", True),
        secure=cfg.get("secure", False),
        samesite=cfg.get("samesite", "Strict"),
        max_age=0,
        expires=0,
        path=cfg.get("path", "/")
    )
    return resp
