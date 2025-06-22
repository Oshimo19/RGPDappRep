from flask import Blueprint, jsonify, g, request, render_template
import logging

index_routes = Blueprint("index", __name__)
logger = logging.getLogger(__name__)

@index_routes.route("/", methods=["GET"])
def home():
    user = getattr(g, "user", None)

    if user and isinstance(user, dict):
        message = f"Bonjour {user.get('email')} ! Rôle : {user.get('role', '').upper()}"
        logger.info(f"[INDEX] Visite utilisateur connecte : {user.get('email')} ({user.get('role')}) - IP: {request.remote_addr}")
    else:
        message = "Bonjour, bienvenue sur le site web !"
        logger.info(f"[INDEX] Visite anonyme - IP: {request.remote_addr}")

    return jsonify({"message": message}), 200

# Route pour stocker token JWT cote client (2.3)
@index_routes.route("/token_front")
def token_front():
    return render_template("token_front.html")
