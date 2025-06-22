"""
conftest.py - parametrable pour app.py (2.2) ou app_2_3.py (2.3)

■ Utilisation :
   # pour tester la v2.2
   APP_MODULE=web.app      pytest …

   # pour tester la v2.3
   APP_MODULE=web.app_2_3  pytest …
"""
import os
import importlib
import pytest
import sys
from pathlib import Path

# ───────────────────────────────────────────────
# S assurer que le dossier racine du projet est dans sys.path
# ───────────────────────────────────────────────
PROJECT_ROOT = Path(__file__).resolve().parents[2]   # …/RGPDapp
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

# ───────────────────────────────────────────────
# Selection dynamique du module Flask
# ───────────────────────────────────────────────
APP_MODULE = os.getenv("APP_MODULE", "web.app")      # defaut : 2.2

try:
    app_module = importlib.import_module(APP_MODULE)
except ModuleNotFoundError as exc:
    raise RuntimeError(
        f"[conftest] Impossible d importer {APP_MODULE}. "
        "Verifiez APP_MODULE ou le PYTHONPATH."
    ) from exc

if not hasattr(app_module, "create_app"):
    raise RuntimeError(f"[conftest] {APP_MODULE} ne contient pas create_app().")

create_app = app_module.create_app   # alias pour fixture

# ───────────────────────────────────────────────
# Fixture client Flask reutilisable
# ───────────────────────────────────────────────
@pytest.fixture
def client():
    app = create_app()
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client
