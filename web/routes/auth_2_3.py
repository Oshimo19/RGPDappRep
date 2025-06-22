"""
Blueprint FRONT – rend la page login et fournit un endpoint
JSON /api/login-json qui renvoie aussi le JWT (pour le JS).
On **ne change pas** auth.py (API) ; on ajoute juste cette
fine couche “front” pour le SPA.
"""
from flask import Blueprint, render_template, request, jsonify, current_app
import logging
import os
import psycopg2
import time

from web.db.hashPassword import verify_password
from web.middlewares.jwt import jwt_middleware

auth_front = Blueprint("auth_front", __name__)

logger = logging.getLogger(__name__)

# Connexion BDD
def get_conn():
    return psycopg2.connect(
        dbname=os.getenv("PGDATABASE"),
        user=os.getenv("PGUSER"),
        password=os.getenv("PGPASSWORD"),
        host=os.getenv("PGHOSTADDR", "127.0.0.1"),
        port=os.getenv("PGPORT", "5432")
    )

# ---------- Page HTML ----------
@auth_front.route("/login", methods=["GET"])
def page_login():
    """Affiche le formulaire de connexion."""
    return render_template("login.html")


# ---------- API JSON dediee au front ----------
@auth_front.route("/api/login-json", methods=["POST"])
def login_json():
    """
    Meme logique que /api/login (back-end) mais :
      • renvoie le JWT dans la reponse JSON (pour localStorage)
      • laisse aussi le Set-Cookie (HttpOnly ⇒ defense en profondeur)
    """
    email = request.form.get("email", "").strip()
    password = request.form.get("password", "")

    # Re-utilise la meme fonction SQL que dans auth.py
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("SELECT id, password, role FROM users WHERE email=%s", (email,))
        row = cur.fetchone()
        cur.close()
        conn.close()
    except Exception as e:
        logger.error(f"[LOGIN_JSON] SQL error: {e}")
        return jsonify({"error": "Erreur serveur"}), 500

    if not row or not verify_password(row[1], password):
        return jsonify({"error": "Echec de connexion"}), 401

    user_id, _, role = row
    token = jwt_middleware.generateToken(user_id, email, role)

    # Reutilise la config cookie RGPD
    cfg = current_app.config.get("COOKIE_CONFIG", {})
    resp = jsonify({"message": "Connexion reussie", "token": token})
    resp.set_cookie(
        cfg.get("name", "session_token"),
        value=token,
        httponly=cfg.get("httponly", True),
        secure=cfg.get("secure", False),
        samesite=cfg.get("samesite", "Strict"),
        max_age=cfg.get("max_age", 900),    # 900 s = 15 min
        expires=int(time.time()) + cfg.get("max_age", 900), # 900 s = 15 min
        path=cfg.get("path", "/"),
    )
    return resp


# ---------- Deconnexion (front) ----------
@auth_front.route("/logout", methods=["POST"])
def logout_front():
    """
    Deconnexion front :
    - vide le cookie
    - renvoie un simple JSON de succes (le JS supprimera
      localStorage et redirigera).
    """
    cfg = current_app.config.get("COOKIE_CONFIG", {})
    resp = jsonify({"message": "Deconnexion reussie"})
    resp.set_cookie(
        cfg.get("name", "session_token"),
        value="",
        httponly=cfg.get("httponly", True),
        secure=cfg.get("secure", False),
        samesite=cfg.get("samesite", "Strict"),
        max_age=0,
        expires=0,
        path=cfg.get("path", "/"),
    )
    return resp
