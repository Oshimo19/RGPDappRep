import time
import logging
from html import escape
from flask import request, jsonify
from web.config import BRUTEFORCE_MAX_ATTEMPTS, BRUTEFORCE_BLOCK_DURATION

logger = logging.getLogger(__name__)

class BruteForceMiddleware:
    """
    Middleware de defense contre les attaques par force brute.
    Blocage temporaire apres N tentatives echouees par email + IP.
    """

    def __init__(self, max_attempts=BRUTEFORCE_MAX_ATTEMPTS, duration=BRUTEFORCE_BLOCK_DURATION):
        self._max = max_attempts
        self._duration = duration
        self.__attempts = {}

    def __key(self, email: str, ip: str) -> str:
        return f"{email}_{ip}"

    def __is_blocked(self, email: str, ip: str) -> bool:
        count, until = self.__attempts.get(self.__key(email, ip), (0, 0))
        return count >= self._max and time.time() < until

    def __increment(self, email: str, ip: str):
        count, _ = self.__attempts.get(self.__key(email, ip), (0, 0))
        count += 1
        until = time.time() + self._duration if count >= self._max else 0
        self.__attempts[self.__key(email, ip)] = (count, until)

    def before_request(self):
        """
        Verifie les tentatives avant chaque requête POST sur /login ou /register.
        Nettoie les champs email/password avec escape().
        """
        path = request.path.lower()
        if path.endswith("/login") or path.endswith("/register"):
            email = escape(request.form.get("email", "").strip().lower())
            password = escape(request.form.get("password", ""))
            ip = request.headers.get("X-Forwarded-For", request.remote_addr).split(",")[0].strip()

            request.cleaned_email = email
            request.cleaned_password = password

            if self.__is_blocked(email, ip):
                logger.warning(f"[BRUTEFORCE] Blocage IP/email : {ip} / {email}")
                return jsonify({"error": "Trop de tentatives, reessayez plus tard."}), 429
        return None

    def after_response(self, response):
        """
        Incremente le compteur apres un echec de login (401).
        """
        if request.path.endswith("/login") and response.status_code == 401:
            email = getattr(request, "cleaned_email", "")
            ip = request.headers.get("X-Forwarded-For", request.remote_addr).split(",")[0].strip()
            self.__increment(email, ip)
        return response


# Instance unique (singleton) reutilisee partout
brute_force_middleware = BruteForceMiddleware()
