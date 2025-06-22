# PATCH WERKZEUG
# Avant toute importation de Flask : supprimer les versions envoy ees par Werkzeug
from werkzeug.serving import WSGIRequestHandler
WSGIRequestHandler.server_version = ""   # « Werkzeug/… » → vide
WSGIRequestHandler.sys_version    = ""   # « Python/… »   → vide
# (on pourrait mettre «Secure» ou laisser vide)

# Logger & OS
import logging
import os

# Flask & env
from flask import Flask
from dotenv import load_dotenv

# Blueprints
from web.routes.index import index_routes
from web.routes.auth import auth_routes
from web.routes.user import user_routes
from web.routes.admin import admin_routes
from web.routes.auth_2_3 import auth_front
from web.routes.user_2_3 import user_front

# Middlewares
from web.middlewares.bruteforce import brute_force_middleware
from web.middlewares.jwt import jwt_middleware
from web.middlewares.errorhandler import error_middleware
from web.middlewares.sanitizer import sanitizer_middleware
from web.middlewares.idor import idor_middleware

# Config
from web.config import SECURITY_HEADERS, SECRET_KEY, COOKIE_CONFIG

# Chargement des variables d environnement
load_dotenv()

def create_app():
    app = Flask(__name__)
    app.secret_key = SECRET_KEY
    app.config["COOKIE_CONFIG"] = COOKIE_CONFIG

    # Logger
    logging.basicConfig(level=logging.INFO)

    # En-têtes de sécurité
    @app.after_request
    def set_security_headers(response):
        from flask import make_response

        if isinstance(response, tuple):
            response = make_response(*response)

        for header, value in SECURITY_HEADERS.items():
            response.headers[header] = value

        response.headers.pop("X-XSS-Protection", None)
        response.headers["X-Frame-Options"] = "DENY"
        return response

    @app.before_request
    def before_all():
        for middleware in (
            sanitizer_middleware,
            brute_force_middleware,
            jwt_middleware,
            idor_middleware,
        ):
            result = middleware.before_request()
            if result:
                return result

    @app.after_request
    def after_all(response):
        response = brute_force_middleware.after_response(response)
        response = error_middleware.after_response(response)
        return response

    # Blueprints API classiques (backend)
    app.register_blueprint(index_routes)
    app.register_blueprint(auth_routes)
    app.register_blueprint(user_routes)
    app.register_blueprint(admin_routes)

    # Blueprints frontend (login, dashboard)
    app.register_blueprint(auth_front)
    app.register_blueprint(user_front)

    return app

# Lancement direct
if __name__ == "__main__":
    app = create_app()
    port = int(os.environ.get("FLASK_PORT_2", "5001"))
    app.run(host="0.0.0.0", port=port, debug=True)