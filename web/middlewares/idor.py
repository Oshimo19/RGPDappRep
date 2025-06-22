import logging
from flask import g, request, jsonify

logger = logging.getLogger(__name__)

class IDORMiddleware:
    """
    Middleware de prevention des acces non autorises de type IDOR (Insecure Direct Object Reference).
    Il protege les routes sensibles selon le rôle (admin/user) et l identifiant de ressource.
    """

    def before_request(self):
        user = getattr(g, "user", None)
        path = request.path.lower()

        if not user or not isinstance(user, dict) or "user_id" not in user:
            return None

        if self.__is_admin_path(path) and user.get("role") != "admin":
            return self.__deny(403, "[SECURITE] Acces admin refuse", user)

        if self.__is_user_id_mismatch(path, user["user_id"]):
            return self.__deny(400, "[IDOR] Mismatch d identifiant", user, path)

        return None

    def __is_admin_path(self, path: str) -> bool:
        return path.startswith("/api/admin")

    def __is_user_id_mismatch(self, path: str, uid: int) -> bool:
        """
        Ex : /api/user/4 → doit correspondre à g.user["user_id"]
        """
        if not path.startswith("/api/user/"):
            return False
        segments = path.rstrip("/").split("/")
        return segments[-1].isdigit() and int(segments[-1]) != uid

    def __deny(self, code: int, log_msg: str, user: dict, path: str = ""):
        logger.warning(f"{log_msg} par {user.get('email')} vers {path}")
        return jsonify({"error": "Acces interdit"}), code


# Instance unique (singleton) reutilisee partout
idor_middleware = IDORMiddleware()
