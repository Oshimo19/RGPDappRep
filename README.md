# RGPDapp

RGPDapp est un projet académique ayant pour objectif de mettre en œuvre concrètement les principes du RGPD (Règlement Général sur la Protection des Données) à travers une application web comme Flask. Ce projet couvre à la fois le backend, la sécurisation des sessions/cookies, l'émission de tokens JWT, et l'intégration d'outils d'analyse de sécurité (SAST & DAST).

## 🎯 Objectifs pédagogiques

1. Respecter les bonnes pratiques RGPD
2. Créer une UI RGPD-Compliant d’une bannière cookie (2.1)
3. Créer une logique de backend de gestion de session avec cookies (2.2)
4. Créer une logique de frontend de gestion de token avec JWT (2.3)
5. Cartographier les traitements opérés sur les données de votre SI (2.4)

## 📁 Arborescence principale

```
RGPDappRep/
├── dast/                    # Tests DAST (OWASP ZAP)
├── sast/                    # Tests SAST (SonarQube)
├── web/                     # Code source Flask (backend + middlewares)
│   ├── db/                  # Scripts BDD PostgreSQL
│   ├── middlewares/        # Middlewares RGPD / Sécurité
│   ├── routes/             # Blueprints Flask (auth, user, admin...)
│   ├── templates/          # Pages HTML (login, dashboard...)
│   ├── tests/              # Tests API et BDD
│   └── config.py           # Configuration Flask / PostgreSQL / JWT
├── .env                    # Configuration sensible (exclue du dépôt public)
├── docker-compose.yml      # Conteneurs PostgreSQL / SonarQube / ZAP
└── README.md
```

## 🧩 Prérequis

- **PostgreSQL** installé localement
- **Docker** installé et fonctionnel
- **Python & dépendances** :
  - `python3`, `python3-venv`, `python3-dev`  
  - Bibliothèques système : `libpq-dev` (nécessaire pour installer `psycopg2`)

## 🛠️ Configuration de PostgreSQL (utilisateur + base de données)

Avant de lancer l’application, veille à ce que l’utilisateur et la base définis dans le fichier `.env` soient créés dans ton instance PostgreSQL locale.

### 1. **Ouvrir le shell PostgreSQL avec l'utilisateur `postgres`** :
```bash
sudo -u postgres psql
```

### 2. **Créer l’utilisateur défini par `PGUSER` avec le mot de passe `PGPASSWORD`**

```bash
CREATE USER <PGUSER> WITH PASSWORD '<PGPASSWORD>';
```

### 3. **Créer la base de données `PGDATABASE` et l’attribuer à l’utilisateur**

```bash
CREATE DATABASE <PGDATABASE> OWNER <PGUSER>;
```

### 4. **Accorder tous les droits à l’utilisateur sur la base**

```bash
GRANT ALL PRIVILEGES ON DATABASE <PGDATABASE> TO <PGUSER>;
```

### 5. **Quitter le shell de PostgreSQL**

```bash
\q
```

Les variables `PGUSER`, `PGPASSWORD` et `PGDATABASE` sont définies dans le fichier `.env`, à créer lors de l'étape suivante.

## ⚙️ Initialisation du projet

### 1. Cloner le dépôt

```bash
git clone https://github.com/Oshimo19/RGPDappRep.git
cd RGPDappRep
```

### 2. Configurer le fichier `.env`

Copier le fichier `.env.template` en `.env` puis l’éditer :

```bash
cp .env.template .env
nano .env
```

Remplir à la main les variables sensibles, à l’exception de :

- `SONAR_TOKEN`
- `ADMIN_PASSWORD_SONAR`

Ces deux variables sont automatiquement renseignées par le script `sast_init.sh`, inutile de les définir manuellement.

Une fois les services Docker démarrés (voir **étape 7**), tu peux déterminer la valeur correcte de `HOST_IP` grâce à la commande suivante :

```bash
docker network inspect rgpdapp_netSec --format='{{range .IPAM.Config}}{{.Gateway}}{{end}}'  
```

Copie ensuite l’IP retournée et colle-la dans la variable `HOST_IP` de ton fichier `.env`.

### 3. Créer un environnement virtuel Python (recommandé)

```bash
python3 -m venv .venv         # Crée un environnement virtuel local
source .venv/bin/activate     # Active l’environnement
```

### 4. Installer les dépendances du projet
```bash
cd web
pip install -r requirements.txt
```
Le fichier `requirements.txt` contient des bibliothèques utilisées par le projet (Flask, psycopg2, python-dotenv, etc.) 

### 5. Initialiser la base de données PostgreSQL

```bash
cd web
make resetDB     # Purge + recréation des tables + insertion des utilisateurs de test
```

### 6. Lancer l'application web Flask

```bash
cd web
bash load_env_conf.sh start web.app      # Pour tester la version cookie (2.2)
bash load_env_conf.sh start web.app_2_3  # Pour tester la version JWT (2.3)
```

### 7. Lancer les services de sécurité (ZAP + SonarQube)

```bash
docker compose up -d --build             # Build + lancement de tous les services
# ou bien :
bash test_lancement_et_verification.sh  # Vérifie les ports + SonarQube UP + ZAP UP
```

## ✅ Scripts de test automatisés

Les scripts de test sont situés dans `web/tests/`. Ils permettent de vérifier automatiquement :
- la validité des cookies RGPD (2.2), cf. `web/tests/api/2.2/`,
- la validité du JWT en frontend (2.3) cf. `web/tests/api/2.3/`,
- le fonctionnement général des routes API (inscription, connexion...),
- la conformité des headers HTTP, logs, etc.

## 🔍 Analyses de sécurité

Le projet intègre :
- SAST (Static Application Security Testing) avec SonarQube (`sast/run_sast_scan.sh`)
- DAST (Dynamic Application Security Testing) avec OWASP ZAP (`dast/run_dast_scan.sh`)

Les rapports sont générés automatiquement dans `sast/reports/` et `dast/reports/`.

## 🧩 Remarques complémentaires

- Le projet respecte les principes SOLID et RGPD, ainsi que les recommandations de sécurité OWASP (voir `doc.md`).
- Des en-têtes HTTP ont été ajoutés pour sécuriser les communications (ex: `X-Content-Type-Options`, `X-Frame-Options`, suppression du header `Server`).
- Un `Makefile` permet de faciliter la gestion de la BDD.
- Le projet utilise exclusivement PostgreSQL, pas SQLite.
- Le projet est hébergé sur GitHub (pas d'image Docker complète par manque de temps).

## 📄 Documentation

Consultez [doc.md](./doc.md) pour :
- l’évaluation complète des principes RGPD, sécurité, SOLID,
- les fonctionnalités implémentées ou abandonnées,
- les axes d’amélioration futurs (Dockerfile, CI/CD, tests bruts, etc).

