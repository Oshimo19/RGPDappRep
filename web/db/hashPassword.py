import logging
from argon2 import PasswordHasher, exceptions

# Initialisation du hasher Argon2id
ph = PasswordHasher()

# Logs de securite
logger = logging.getLogger(__name__)

# Fonction de hachage
def hash_password(password: str) -> str:
    try:
        hashed = ph.hash(password)
        logger.info("[HASH] Mot de passe hache avec succes : *****")   # RGPD -> Pas de hash visible
        return hashed
    except Exception as e:
        logger.error("[HASH] Erreur : Hachage du mot de passe")
        raise e

# Fonction de verification de mot de passe
def verify_password(storedHash: str, password: str) -> bool:
    try:
        return ph.verify(storedHash, password)
    except exceptions.VerifyMismatchError:
        logger.warning("[AUTH] Echec : Mauvais mot de passe")
        return False
    except Exception:
        logger.error("[AUTH] Erreur : Verification du mot de passe")
        return False
