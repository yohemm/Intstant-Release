# 📗 **Projet : Instant-Release — Universal Semantic Versioning & CI/CD Toolkit**

## 🧭 Vision & Objectif

**Instant-Release** est une **GitHub Action composite (Bash-based)** permettant d’automatiser le versioning sémantique, la génération de changelog et la création de tags ou releases, tout en restant **100 % natif GitHub Actions** — sans dépendance Node.js, Python ou conteneur.

> L’objectif : devenir **le couteau suisse universel du versioning et de la release automation**, aussi modulaire et polyvalent que `actions/checkout`.

L’action doit être capable de :

* Gérer tout le cycle de versioning (lecture, bump, changelog, tag, release),
* S’adapter à **tout environnement CI/CD** (monorepo, microservices, mono-package),
* Fournir des **modes d’exécution indépendants ou combinés** (`get`, `bump`, `tag`, `release`, etc.),
* Être **hautement configurable via inputs et fichiers de config YAML/JSON**,
* Offrir une **expérience de logs et d’audit claire** avec préfixes `[AUDIT]`.

---

## ⚙️ Nature du projet

| Élément                 | Détail                                                           |
| ----------------------- | ---------------------------------------------------------------- |
| **Type d’action**       | Composite + Scripts Bash                                         |
| **Langage principal**   | Bash / Shell POSIX                                               |
| **Runtime**             | GitHub Hosted Runners (Ubuntu)                                   |
| **Publication**         | GitHub Marketplace (prévue, non prioritaire)                     |
| **Approche**            | Plug & Play, paramétrable uniquement par inputs et fichiers YAML |
| **Architecture future** | Modulaire (modes fonctionnels distincts)                         |

---

## 🧩 Modules fonctionnels (Features détaillées)

Voici la **liste complète des fonctionnalités** prévues dans la version avancée.
Elles sont regroupées par catégorie et marquées selon leur rôle :

| 🏷️ Catégorie                 | 🧠 Fonction                  | Description                                                                | Statut        |
| ----------------------------- | ---------------------------- | -------------------------------------------------------------------------- | ------------- |
| **Versioning Core**           | `get-current-version`        | Récupère la version actuelle (tag, fichier, config)                        | ✅ MVP         |
|                               | `bump-version`               | Calcule et applique le bump sémantique (`major`, `minor`, `patch`, `auto`) | ✅ MVP         |
|                               | `extract-breaking-changes`   | Identifie les commits contenant `BREAKING CHANGE` ou `!:`                  | 🧩 À intégrer |
|                               | `get-commit-stats`           | Fournit des stats : nb commits, contributeurs, fichiers modifiés           | 🧩 À intégrer |
| **Changelog Management**      | `generate-changelog`         | Génère ou met à jour le `CHANGELOG.md` depuis les commits                  | ✅ MVP         |
|                               | `append-changelog`           | Ajoute une nouvelle section à un changelog existant                        | 🧩 À intégrer |
|                               | `extract-changelog`          | Extrait la dernière section du changelog                                   | 🧩 À intégrer |
|                               | `changelog-to-release-notes` | Convertit changelog en release notes (Markdown/HTML)                       | 🧩 À intégrer |
| **Tagging & Release**         | `create-tag`                 | Crée et pousse un tag `vX.Y.Z` sur le repo                                 | ✅ MVP         |
|                               | `gh-release`                 | Crée une release GitHub avec changelog et assets                           | 🧩 À intégrer |
| **Monorepo / Packages**       | `detect-changed-packages`    | Détecte quels dossiers/packages ont changé                                 | 🧩 À intégrer |
|                               | `package-release`            | Gère bump, changelog et tag pour chaque package du monorepo                | 🧩 À intégrer |
| **CI/CD & Sécurité**          | `dry-run`                    | Mode simulation sans push/tag                                              | ✅ MVP         |
|                               | `retry-on-failure`           | Réexécution automatique en cas d’erreur réseau                             | 🧩 À intégrer |
|                               | `idempotent-check`           | Vérifie si un tag/version existe déjà avant exécution                      | 🧩 À intégrer |
|                               | `validate-token`             | Vérifie que le token dispose des permissions nécessaires                   | 🧩 À intégrer |
|                               | `auto-commit`                | Commit automatique du changelog/version                                    | ✅ MVP         |
| **Reporting & Extensibilité** | `generate-release-metadata`  | Produit un artefact JSON complet avec métadonnées de release               | 🧩 À intégrer |
|                               | `notify-slack`               | Envoie un résumé de release sur Slack/Discord/Teams                        | 🧩 À intégrer |
|                               | `plugin-run`                 | Exécute un script utilisateur externe après release                        | 🧩 À intégrer |
| **Quality & Guardrails**      | `semantic-guard`             | Vérifie la conformité des messages de commit                               | 🧩 À intégrer |
| **Configuration avancée**     | `config-merge`               | Fusionne inputs et fichier `.instantrelease.yml` pour une config unifiée   | 🧩 À intégrer |

---

## 🧱 Architecture fonctionnelle (vue technique simplifiée)

```
┌──────────────────────────────────────┐
│          Instant-Release             │
│        (composite + bash)            │
└───────────────┬──────────────────────┘
                │
                ▼
        [ Entrée utilisateur ]
    ┌──────────────────────────────┐
    │ Inputs YAML + config externe │
    └──────────────────────────────┘
                │
                ▼
        [ Core execution logic ]
 ┌────────────────────────────────────┐
 │ 1️⃣ Analyse commits (patterns)      │
 │ 2️⃣ Calcul bump                    │
 │ 3️⃣ Détection BREAKING CHANGE      │
 │ 4️⃣ Génération CHANGELOG.md        │
 │ 5️⃣ Création TAG Git               │
 │ 6️⃣ (Option) Création Release GH   │
 │ 7️⃣ Auto-commit & Audit Logs       │
 │ 8️⃣ Export outputs + JSON summary  │
 └────────────────────────────────────┘
                │
                ▼
        [ Sorties / Outputs CI ]
 ┌─────────────────────────────────────────┐
 │ - Version bump                         │
 │ - Fichier changelog                    │
 │ - Tag créé                             │
 │ - Release GH                           │
 │ - Artefact JSON                        │
 └─────────────────────────────────────────┘
```

---

## ⚙️ Inputs actuels (issus du MVP)

| Nom                          | Description                                      | Par défaut                                     |
| ---------------------------- | ------------------------------------------------ | ---------------------------------------------- |
| `trigger-branches`           | Branches sur lesquelles déclencher le versioning | `main,develop`                                 |
| `breaking-change-indicators` | Identifiants de breaking changes                 | `BREAKING CHANGE,!:,\!:`                       |
| `feature-types`              | Types de commits considérés comme features       | `feat,✨,🚀`                                    |
| `fix-types`                  | Types de commits considérés comme fixes          | `fix,🐛`                                       |
| `refactor-types`             | Types de commits considérés comme refactor/perf  | `refactor,♻️,perf,⚡,🎨`                        |
| `git-user-name`              | Nom d’utilisateur Git pour commits               | `github-actions[bot]`                          |
| `git-user-email`             | Email Git pour commits                           | `github-actions[bot]@users.noreply.github.com` |
| `initial-version`            | Version initiale si aucun tag n’existe           | `v0.0.1`                                       |
| `generate-changelog`         | Génère ou met à jour le `CHANGELOG.md`           | `true`                                         |
| `changelog-file`             | Chemin du changelog                              | `CHANGELOG.md`                                 |
| `auto-commit`                | Commit automatique du changelog                  | `true`                                         |
| `create-tags`                | Crée et pousse un tag Git                        | `true`                                         |
| `create-release`             | Crée une release GitHub                          | `false`                                        |
| `debug`                      | Active les logs détaillés                        | `false`                                        |

---

## 🧾 Outputs actuels

| Nom                   | Description                                      |
| --------------------- | ------------------------------------------------ |
| `current-version`     | Version actuelle ou nouvellement créée           |
| `version-bump`        | Type de bump (`major`, `minor`, `patch`, `none`) |
| `changelog-generated` | Indique si le changelog a été modifié            |
| `tag-created`         | Indique si un tag a été créé                     |

---

## 🧰 Inputs/Outputs à étendre

### Nouveaux inputs à prévoir

| Input            | Description                                                             |
| ---------------- | ----------------------------------------------------------------------- |
| `mode`           | Mode d’exécution : `get`, `bump`, `changelog`, `tag`, `release`, `full` |
| `config-file`    | Chemin vers `.instantrelease.yml` pour la configuration externe         |
| `dry-run`        | Active le mode simulation sans push/tag                                 |
| `retry-attempts` | Nombre de tentatives sur erreur réseau                                  |
| `monorepo`       | Active le mode multi-package                                            |
| `slack-webhook`  | URL de notification Slack/Discord                                       |
| `plugins`        | Liste de scripts externes à exécuter post-release                       |
| `output-format`  | Format de sortie (markdown, json, html)                                 |

### Nouveaux outputs à générer

| Output             | Description                           |
| ------------------ | ------------------------------------- |
| `release-url`      | URL de la release GitHub créée        |
| `release-metadata` | JSON complet des infos de release     |
| `breaking-changes` | Liste des commits à breaking change   |
| `commit-stats`     | Statistiques sur la release           |
| `package-list`     | Packages modifiés en mode monorepo    |
| `retry-status`     | Statut après réessais                 |
| `config-merged`    | Confirmation du merge config + inputs |

---

## 🧩 Exemple futur d’usage

```yaml
- name: Instant Release - Modular Mode
  uses: yohem/instant-release@v2
  with:
    mode: bump+changelog+tag
    trigger-branches: main,develop
    changelog-file: docs/CHANGELOG.md
    create-release: true
    dry-run: false
    plugins: |
      ./scripts/post-publish.sh
    slack-webhook: ${{ secrets.SLACK_WEBHOOK }}
```

---

## 🧠 Vision globale (v2 → v3)

| Étape            | Objectif                                                                 | Périmètre                                                 |
| ---------------- | ------------------------------------------------------------------------ | --------------------------------------------------------- |
| **v2 (Q4 2025)** | Refactor modulaire complet + ajout des 10 features core                  | bump, changelog, tag, dry-run, retry, metadata, plugin    |
| **v3 (2026)**    | Support monorepo + configuration externe + intégrations Slack/Release GH | detect-changed-packages, config merge, release automation |
| **v4 (2026+)**   | Ouverture API + extensions externes (plugins communautaires)             | plugin marketplace, templates, custom changelog schemas   |

---

## 🔒 Sécurité & permissions

* **Token requis** : `${{ secrets.GITHUB_TOKEN }}` ou `GH_TOKEN` custom.
* **Scopes minimaux** :

  * `contents: write` pour commits et changelog,
  * `metadata: read` pour stats,
  * `issues: read` pour release notes enrichies.
* **Validation automatique** via fonction `validate-token`.

---

## 📊 Exemple d’Audit Log attendu

```
[AUDIT] Starting release workflow (v1.4.0)
[AUDIT] Found last tag: v1.3.0
[AUDIT] Detected bump type: minor (feat)
[AUDIT] Commits since last tag: 8
[AUDIT] Generating changelog file
[AUDIT] Committing changelog and tag v1.4.0
[AUDIT] Dry-run mode: disabled
[AUDIT] Push complete — Release created successfully
```

---

## 🧩 Fichier de config externe (optionnel)

`.instantrelease.yml`

```yaml
versioning:
  initial: v0.0.1
  tag_prefix: "v"
  monorepo: false

changelog:
  enabled: true
  file: CHANGELOG.md
  template: default

release:
  create: true
  publish_to: github
  notify_slack: true

plugins:
  - ./scripts/update-docs.sh
  - ./scripts/notify-api.sh
```

---

## 🧾 Conclusion

**Instant-Release** vise à devenir :

> une *GitHub Action composite universelle*, modulaire, légère et native, qui automatise **toutes les étapes de versioning et de release**, adaptable à tous contextes CI/CD.

🧩 L’évolution prochaine va structurer l’action autour de **modes indépendants**, d’une **configuration unifiée**, et de **fonctionnalités optionnelles hautement modulaires** :

* 🔁 Rejouabilité (idempotence, retry)
* 🧠 Intelligence sémantique (commit parsing avancé)
* 🧾 Génération documentaire (CHANGELOG + release notes)
* 🔗 Connecteurs (Slack, GH Release, plugins)
* 🧱 Support monorepo et config YAML