# 📘 Documentation du projet RGPDapp

## 🎯 Objectif du projet

Ce projet a été réalisé dans le cadre d’un exercice de mise en conformité RGPD d’une application Web. Il s’articule autour des étapes suivantes :

| Étape | Description |
|-------|-------------|
| 2.1 | Création d’une bannière de consentement RGPD côté frontend |
| 2.2 | Gestion de session via cookie sécurisé RGPD côté backend |
| 2.3 | Authentification JWT pour le frontend |
| 2.4 | Cartographie des traitements des données (non réalisée) |

---

## ✅ Fonctionnalités mises en œuvre

- 🔐 Authentification par mot de passe avec hash sécurisé
- 🧾 Gestion de session via cookie HttpOnly/SameSite (étape 2.2)
- 🔑 Émission de JWT signé (étape 2.3)
- 💾 Stockage localStorage du JWT côté frontend
- 🛡️ Protection contre la force brute via middleware
- 🧼 Middleware de sanitation d’entrée (XSS/SQLi)
- 📋 Logger centralisé (log fichier avec niveau paramétrable)
- 🧪 Scripts automatisés de tests (cookie RGPD, JWT, etc.)
- 📦 Fichiers Makefile et .env modèles fournis
- 🧱 Headers HTTP sécurisés (masquage Server, en-têtes OWASP)

---

## 📊 État d’avancement

| Élément | Réalisé |
|--------|--------|
| Backend Flask modulaire | ✅ |
| Cookies RGPD (2.2) | ✅ |
| JWT Frontend (2.3) | ✅ |
| DAST (OWASP ZAP) | ✅ |
| SAST (SonarQube) | ✅ |
| UI Bannière cookie (2.1) | 🔸 En partie |
| Cartographie des traitements (2.4) | ❌ |
| Pipeline CI/CD | ❌ |
| Image Docker complète | ❌ |
| Tests bruteforce automatiques | ❌ |
| Tests logs, accès par curl, types de données | ❌ |

---

## 📌 Ce qui aurait pu être fait (manque de temps)

| Élément | Détail |
|--------|--------|
| Dockerisation complète | Backend, BDD, front, .env template |
| CI/CD | Jenkins, GitHub Actions ou GitLab CI |
| Pipeline de test automatisée | Scripts Bash + déploiement |
| Cartographie des traitements | PlantUML / Mermaid |
| Tests automatisés XSS, SQLi, brute-force | via curl, OWASP ZAP |
| Politique de journalisation claire | retention, horodatage, rotation |
| Accès aux routes + logs des erreurs par curl | non testés |

---

## 📎 Principes RGPD : respectés ou non ?

| Principe RGPD | Respecté ? | Commentaire |
|----------------|------------|-------------|
| Licéité, loyauté, transparence | ✅ | Les traitements sont explicitement codés et limités |
| Limitation des finalités | ✅ | Finalité unique : authentification et accès |
| Minimisation des données | ✅ | Email et mot de passe uniquement |
| Exactitude des données | 🔸 | Pas de vérification email (mail de test uniquement) |
| Limitation de conservation | 🔸 | Pas de politique automatisée de purge |
| Intégrité et confidentialité | ✅ | HTTPS présumé, cookies sécurisés, JWT signé |
| Responsabilité (accountability) | ✅ | Structure claire + logs centralisés + tests |

---

## 🛡️ Principes de sécurité : respectés ou non ?

| Principe sécurité | Respecté ? | Détail |
|---------------------|------------|--------|
| Moindre privilège | ✅ | Pas de rôle ADMIN par défaut |
| Séparation des privilèges | 🔸 | Limité à rôle USER/ADMIN |
| Économie de mécanisme | ✅ | Architecture simple et modulaire |
| Défaut de refus | ✅ | Accès interdit sans token ou session |
| Médiation complète | ✅ | Contrôle JWT et session à chaque accès |
| Séparation des fonctions | ✅ | Routes admin isolées |
| Défense en profondeur | ✅ | JWT, cookies, sanitation, bruteforce |
| Conception ouverte | ✅ | Code source disponible |
| Acceptabilité | ✅ | UI simple, formulaires clairs |
| Accountability | ✅ | Logs + structure modulaire |
| Hypothèse minimale | ✅ | Variables minimales exposées |

---

## 🧱 Principes SOLID (POO) : respectés ou non ?

| Principe SOLID | Respecté ? | Détail |
|----------------|------------|--------|
| Single Responsibility (SRP) | ✅ | Routes, middlewares, services bien séparés |
| Open/Closed (OCP) | 🔸 | Peu de classes étendables, mais bonne base |
| Liskov Substitution (LSP) | ✅ | Pas de hiérarchie complexe nécessitant cela |
| Interface Segregation (ISP) | ✅ | Aucun surdesign ou superclasse inutile |
| Dependency Inversion (DIP) | 🔸 | Injection non formalisée (pas d’interface), mais séparation claire |

---

## 🔍 Ce que j’ai fait de plus par rapport à l’énoncé

- 🔎 DAST avec OWASP ZAP (scan actif + rapport)
- 🧠 SAST avec SonarQube (qualité de code)
- 🧪 Scripts Bash automatisés (test RGPD cookies/JWT)
- 📄 Makefile et PostgreSQL testable facilement
- 🔐 Middleware bruteforce et sanitation
- 📋 Logger centralisé paramétrable
- 🧱 Masquage de la version serveur (`Server:` vide)
- 🔐 Headers HTTP recommandés (cheatsheet OWASP)

---

## 🤖 Remerciements

💬 L’assistant IA ChatGPT a été d’une aide précieuse pour :
  - structurer les middlewares,
  - améliorer la sécurité,
  - corriger les erreurs,
  - rédiger des scripts de test Bash,
  - générer les structures Markdown.

Merci 🙏

---

## 🔚 Conclusion

Le projet a respecté les contraintes pédagogiques, a été fortement enrichi (SAST, DAST, logs, sécurité HTTP, Makefile, tests Bash/Python) et se base sur une structure modulaire simple respectant les principes **SOLID**, **POO**, **sécurité** et **RGPD**.

Certaines fonctionnalités n’ont pas pu être implémentées par manque de temps, mais la base est solide, extensible, et documentée.

> 📁 Ce projet est hébergé sous forme de **projet GitHub** (non dockerisé).

---

Dernière mise à jour : 2025-06-22
