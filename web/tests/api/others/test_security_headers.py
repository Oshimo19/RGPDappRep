import subprocess
import time
import requests
import pytest
import os
import signal
from dotenv import load_dotenv

# Charger .env
load_dotenv()

BASE_URL = os.getenv("BASE_URL")

@pytest.fixture(scope="module")
def flask_server():
    """Demarre l application Flask temporairement."""
    process = subprocess.Popen(
        ["python3", "-m", "web.app"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    time.sleep(2)  # Attend que le serveur demarre
    yield process
    process.send_signal(signal.SIGINT)
    
    try:
        process.wait(timeout=3)
    except subprocess.TimeoutExpired:
        process.kill()

def test_security_headers(flask_server):
    """Verifie les en-têtes de securite OWASP."""
    try:
        response = requests.get(BASE_URL)
    except Exception as e:
        pytest.fail(f"Erreur de connexion a {BASE_URL}: {e}")

    headers = response.headers

    # En-tetes requis selon la cheat sheet OWASP
    expected_headers = {
        "Content-Security-Policy",
        "X-Content-Type-Options",
        "X-Frame-Options",
        "Referrer-Policy",
        "Permissions-Policy",
        "Strict-Transport-Security",
    }

    for h in expected_headers:
        assert h in headers, f"En-tete manquant : {h}"

    # En-tete a eviter
    assert "X-XSS-Protection" not in headers, "X-XSS-Protection devrait etre supprime"

    # Verifie anonymisation de Server même en cas de doublons
    server_header = headers.get("Server", "")
    assert all(v.strip() == "" for v in server_header.split(",")), f"L'en-tête Server doit etre vide, trouve : {server_header!r}"
