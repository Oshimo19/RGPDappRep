import base64
import hashlib
import hmac
import json
import logging
import uuid
import time
from flask import request, g, current_app
from web.config import JWT_EXPIRATION_SECONDS, JWT_ALGORITHM

logger = logging.getLogger(__name__)

class JWTMiddleware:
    """
    Middleware JWT : decode le token JWT si present dans l en-tete Authorization.
    Initialise g.user si le token est valide.
    """

    def __init__(self):
        self.__secret = None
        self.__revoked_tokens = {}  # {jti: exp_timestamp}

    def before_request(self):
        g.user = None
        token = self.__extract_token_from_request()

        if not token:
            return  # Aucun token fourni

        payload = self.__decode_jwt(token)

        if payload and self.__is_token_valid(payload):
            g.user = payload
        else:
            logger.warning("[JWT] Token invalide, expire ou revoque")

    def __extract_token_from_request(self) -> str | None:
        # 1. Authorization: Bearer <token>
        auth_header = request.headers.get("Authorization", "")
        if auth_header.startswith("Bearer "):
            return auth_header.split(" ", 1)[1]

        # 2. Cookie session_token
        cookie_cfg = current_app.config.get("COOKIE_CONFIG", {})
        return request.cookies.get(cookie_cfg.get("name", "session_token"))

    def __decode_jwt(self, token: str):
        try:
            header_b64, payload_b64, sig_b64 = token.split(".")
            message = f"{header_b64}.{payload_b64}"
            expected_sig = self.__sign_jwt(message)
            
            if not hmac.compare_digest(sig_b64, expected_sig):
                logger.warning("[JWT] Signature invalide")
                return None

            # Ajout padding base64
            padded_payload = payload_b64 + "==" if len(payload_b64) % 4 else payload_b64
            payload_json = base64.urlsafe_b64decode(padded_payload)
            
            return json.loads(payload_json)
        except Exception as e:
            logger.warning(f"[JWT] Token malforme : {str(e)}")
            return None

    def __sign_jwt(self, message: str) -> str:
        if self.__secret is None:
            self.__secret = current_app.secret_key.encode()
        
        digest = hmac.new(self.__secret, message.encode(), hashlib.sha256).digest()
        
        return base64.urlsafe_b64encode(digest).decode().rstrip("=")

    def __is_token_valid(self, payload: dict) -> bool:
        now = int(time.time())
        exp = payload.get("exp", 0)
        jti = payload.get("jti")

        if exp <= now:
            return False

        self.__cleanup_revoked_tokens()
        if jti in self.__revoked_tokens:
            logger.warning(f"[JWT] Token revoque (jti={jti})")
            return False

        return True

    def __cleanup_revoked_tokens(self):
        now = int(time.time())
        self.__revoked_tokens = {
            jti: exp for jti, exp in self.__revoked_tokens.items() if exp > now
        }

    def revoke_token(self, token: str):
        payload = self.__decode_jwt(token)
        if payload and "jti" in payload and "exp" in payload:
            self.__revoked_tokens[payload["jti"]] = payload["exp"]
            logger.info(f"[JWT] Token revoque (jti={payload['jti']})")
        else:
            logger.warning("[JWT] Impossible de revoquer le token (invalide ou incomplet)")

    def generateToken(self, user_id: int, email: str, role: str = "user", duration_sec: int = JWT_EXPIRATION_SECONDS) -> str:
        now = int(time.time())
        header = {"alg": JWT_ALGORITHM, "typ": "JWT"}
        payload = {
            "user_id": user_id,
            "email": email,
            "role": role.upper(),
            "iat": now,
            "exp": now + duration_sec,
            "jti": str(uuid.uuid4())
        }

        header_enc = base64.urlsafe_b64encode(json.dumps(header).encode()).decode().rstrip("=")
        payload_enc = base64.urlsafe_b64encode(json.dumps(payload).encode()).decode().rstrip("=")
        message = f"{header_enc}.{payload_enc}"
        signature = self.__sign_jwt(message)

        return f"{message}.{signature}"


# Instance unique (singleton) reutilisee partout
jwt_middleware = JWTMiddleware()
