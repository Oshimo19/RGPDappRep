import re

def is_valid_email(email: str) -> bool:
    return bool(re.fullmatch(r"^[\w\.-]+@[\w\.-]+\.\w{2,}$", email))

def is_valid_name(name: str) -> bool:
    return bool(re.fullmatch(r"^[A-Za-z\s\-']{1,100}$", name))

def is_strong_password(password: str) -> bool:
    if not 12 <= len(password) <= 64:
        return False
    if not re.search(r"[a-z]", password): return False
    if not re.search(r"[A-Z]", password): return False
    if not re.search(r"\d", password): return False
    if not re.search(r"[^\w\s]", password): return False  # au moins 1 caractère spécial
    return True
