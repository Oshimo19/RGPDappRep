"""
Blueprint FRONT - sert la page dashboard utilisateur (SPA).
La route API /api/user/dashboard existe deja dans user.py.
"""
from flask import Blueprint, render_template

user_front = Blueprint("user_front", __name__)


@user_front.route("/user_dashboard", methods=["GET"])
def page_dashboard():
    """Page tableau de bord (HTML + JS)."""
    return render_template("user_dashboard.html")
