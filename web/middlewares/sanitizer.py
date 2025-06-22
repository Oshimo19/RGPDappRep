import re
import html
import logging
from flask import request

logger = logging.getLogger(__name__)

class InputSanitizerMiddleware:
    """
    Middleware de desinfection d'entree contre les injections XSS et SQL.
    Il nettoie les champs de formulaire (POST/PUT/PATCH) et expose request.cleaned_data.
    """

    def __init__(self):
        self._xss_script = re.compile(r"<\s*script[^>]*>.*?<\s*/\s*script\s*>", re.IGNORECASE)
        self._html_tags = re.compile(r"<[^>]+>")
        self._sql_keywords = re.compile(
            r"(--|\b(SELECT|INSERT|DELETE|UPDATE|DROP|UNION|ALTER|CREATE|EXEC|TRUNCATE|CHAR|CAST|CONVERT)\b)",
            re.IGNORECASE
        )

    def before_request(self):
        """
        Intercepte les requêtes POST/PUT/PATCH et nettoie tous les champs texte.
        Les champs nettoyes sont disponibles via request.cleaned_data.
        """
        if request.method in {"POST", "PUT", "PATCH"}:
            cleaned = {}
            for key, value in request.form.items():
                if isinstance(value, str):
                    cleaned[key] = self._sanitize_input(value)
            request.cleaned_data = cleaned

    def _sanitize_input(self, value: str) -> str:
        """
        Applique un enchaînement de nettoyages :
        - suppression des balises <script>
        - suppression des autres balises HTML
        - suppression des mots-cles SQL
        - echappement des caracteres HTML/XSS
        """
        original = value
        value = self._xss_script.sub("", value)
        value = self._html_tags.sub("", value)
        value = self._sql_keywords.sub("", value)
        value = html.escape(value)
        cleaned = value.strip()

        # Journalisation pour suivi debug
        if original != cleaned:
            logger.debug(f"[SANITIZER] Nettoyage applique: '{original}' → '{cleaned}'")

        return cleaned


# Instance unique (singleton) reutilisee partout
sanitizer_middleware = InputSanitizerMiddleware()
