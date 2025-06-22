# ────────────────  CONFIG GLOBALE  ────────────────
SHELL := /bin/bash
PY    := python3
export PYTHONPATH := $(shell pwd)        # « web/ »

BLUE  := \033[36m
RESET := \033[0m
.DEFAULT_GOAL := help

# ────────────────  BDD  ────────────────
resetDB: ## Réinitialise complètement la BDD (DROP + CREATE + données démo)
	@echo "=== Réinitialisation de la BDD ==="
	@cd db && ./reset_db.sh

show:    ## Affiche le contenu des tables (users / deletedUsers)
	@echo "=== Affichage contenu des tables ==="
	@./db/show_users.sh

# ────────────────  TESTS UNITAIRES  ────────────────
define run_pytest
	@echo "=== $1 ==="; \
	pytest -q --disable-warnings $2
endef

false_insert: ## Test d’insertion d’utilisateurs invalides
	$(call run_pytest,Insertion utilisateurs invalides,tests/db/test_insert_false_users_pytest.py)

insert: ## Test d’insertion d’un utilisateur valide
	$(call run_pytest,Insertion utilisateur,tests/db/test_insert_user_pytest.py)

login:  ## Test de connexion d’un utilisateur
	$(call run_pytest,Connexion utilisateur,tests/db/test_login_user_pytest.py)

delete: ## Test de suppression d’un utilisateur
	$(call run_pytest,Supression utilisateur,tests/db/test_delete_user_pytest.py)

purge:  ## Purge des données personnelles (> 30 jours)
	$(call run_pytest,Purge données personnelles,tests/db/test_purge_pytest.py)

all: insert login delete  ## Chaîne complète : insert → login → delete

# ────────────────  AIDE  ────────────────
help:
	@echo "Commandes disponibles :"
	@grep -E '^[a-zA-Z0-9_-]+:.*?##' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS=":.*?## "}; {printf "  $(BLUE)%-18s$(RESET) %s\n", $$1, $$2}'

.PHONY: resetDB show false_insert insert login delete purge all help
