import logging
from flask import request, jsonify
from web.config import HTTP_ERROR_CODES

logger = logging.getLogger(__name__)

class ErrorMiddleware:
    """
    Middleware pour intercepter les reponses HTTP avec des erreurs client/serveur.
    Renvoie un message generique JSON et journalise l acces.
    """

    def __init__(self, allowed_codes=None):
        self._allowed_codes = allowed_codes or HTTP_ERROR_CODES

    def after_response(self, response):
        """
        Transforme les erreurs HTML (par defaut Flask) en reponse JSON sécurisee.
        """
        content_type = response.content_type or ""
        if response.status_code in self._allowed_codes and content_type.startswith("text/html"):
            logger.warning(f"[ERREUR HTTP {response.status_code}] sur {request.path}")
            return jsonify({"error": "Acces interdit ou erreur technique"}), response.status_code
        return response


# Instance unique (singleton) reutilisee partout
error_middleware = ErrorMiddleware()
