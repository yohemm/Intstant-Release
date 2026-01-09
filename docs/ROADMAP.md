# InstantRelease - Fiche de route (avant implementation)

Objectif : valider les choix techniques et le perimetre avant de coder.

## Documents lies
- `docs/TECHNICAL_DOCS.md` : perimetre POC + details d'implementation
- `docs/FULL_DOCS.md` : vision complete (cible long terme)

---

## 1. Decisions a valider
- format de config unique : `.instantrelease.yml`
- type de GitHub Action : composite vs JavaScript
- convention de commits par defaut (Angular)
- strategie de versioning (auto + override)
- politique d'echec : fail-fast vs warnings

---

## 2. Architecture cible (POC)
- un orchestrateur principal (script bash)
- modules scripts : git / versioning / changelog / release
- lib commune : logging, validation, utils

---

## 3. Flux POC (MVP)
1) Charger config
2) Verifier prerequis (token, repo, branche)
3) Calculer version
4) Generer changelog
5) Tag + release GitHub

---

## 4. Backlog technique par lot

### Lot 1 - POC livrable
- lecture config YAML
- calcul version via commits
- changelog Markdown
- creation tag + release
- dry-run

### Lot 2 - Qualite & robustesse
- validation schema YAML
- gestion erreurs centralisee
- logs [AUDIT] et [DEBUG]
- tests unitaires scripts

### Lot 3 - Securite & compliance
- scan dependances
- scan secrets
- rapport audit JSON

### Lot 4 - Extensibilite
- webhooks pre/post
- plugins pre/post
- hooks on-failure

### Lot 5 - Vision long terme (FULL_DOCS)
- monorepo + releases par package
- matrices de deploiement
- SBOM + supply-chain checks
- rapports multi-formats

---

## 5. Questions ouvertes
- format exact des messages de commit supportes ?
- outils pour scans (npm audit, osv, trufflehog) ?
- mode release : tag uniquement vs release GitHub obligatoire ?
- doit-on gerer monorepo dans la v1 ?

---

## 6. Definition of Done (POC)
- execution de bout en bout sur un repo exemple
- tag + release crees sans erreur
- changelog lisible
- config unique dans `.instantrelease.yml`
- mode `dry-run` fonctionnel
