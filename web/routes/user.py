from flask import Blueprint, jsonify, g, request
import logging

user_routes = Blueprint("user", __name__, url_prefix="/api/user")
logger = logging.getLogger(__name__)

@user_routes.route("/dashboard", methods=["GET"])
def user_dashboard():
    user = getattr(g, "user", None)

    email = user.get("email") if isinstance(user, dict) else "anonyme"
    role = user.get("role", "").upper() if isinstance(user, dict) else "AUCUN"

    if not user or role != "USER":
        logger.warning(f"[USER] Acces refuse pour IP {request.remote_addr} avec utilisateur {email}")
        return jsonify({"error": "Acces non autorise"}), 403

    return jsonify({
        "message": "Bienvenue sur votre tableau de bord",
        "email": email,
        "role": role
    }), 200
