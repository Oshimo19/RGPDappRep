from flask import Blueprint, jsonify, g, request
import logging

admin_routes = Blueprint("admin", __name__, url_prefix="/api/admin")
logger = logging.getLogger(__name__)

@admin_routes.route("/dashboard", methods=["GET"])
def admin_dashboard():
    user = getattr(g, "user", None)

    if not user or not isinstance(user, dict) or user.get("role", "").upper() != "ADMIN":
        logger.warning(f"[ADMIN] Acces refuse à /dashboard pour IP {request.remote_addr} avec user {user.get('email', 'inconnu') if user else 'anonyme'}")
        return jsonify({"error": "Acces interdit"}), 403

    # Reponse securisee : pas de donnees sensibles
    return jsonify({
        "message": f"Panneau d'administration",
        "email": user.get("email"),
        "role": user.get("role")
    }), 200
