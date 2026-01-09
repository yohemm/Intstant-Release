# <a href="https://yohemm.github.io/Intstant-Release/" target="_blank">Instant-Release</a>

<p align="center">
  <img src="https://nas.vaxelaire.fr/public.php/dav/files/Yn5yjmeHYMPtsX7/?accept=zip" alt="InstantRelease Hero" />
</p>

<p align="center">
  <a href="https://github.com/yohemm/Intstant-Release/actions/workflows/poc-tests-minimal.yml">
    <img alt="POC Tests Minimal" src="https://github.com/yohemm/Intstant-Release/actions/workflows/poc-tests-minimal.yml/badge.svg" />
  </a>
  <a href="https://github.com/yohemm/Intstant-Release/actions/workflows/poc-tests-verbose.yml">
    <img alt="POC Tests Verbose" src="https://github.com/yohemm/Intstant-Release/actions/workflows/poc-tests-verbose.yml/badge.svg" />
  </a>
  <a href="LICENSE.md">
    <img alt="License" src="https://img.shields.io/badge/license-Non--Commercial-blue" />
  </a>
</p>

InstantRelease est une GitHub Action CI/CD qui automatise le versioning, le changelog, le tag et la release. L'objectif: livrer plus vite, sans erreurs humaines, avec un pipeline propre et reproductible.

## Pourquoi InstantRelease

- Versioning automatique base sur vos commits (convention type Angular)
- Changelog clair, structure et lisible par l'equipe
- Tags et releases GitHub generes sans friction
- Mode POC rapide a integrer, extensible vers une version complete

## Ce que vous gagnez

- Moins de temps perdu en release manuelles
- Une version coherent a chaque merge
- Une trace propre pour vos utilisateurs et vos stakeholders

## Fonctionnalites (POC)

- [x] Detection du bump (major/minor/patch) via commits
- [x] Generation de changelog
- [x] Creation de tag
- [x] Tests locaux (bash + Docker) et CI POC
- [ ] Creation de release GitHub (prochaine etape)
- [ ] Synchronisation de version dans plusieurs fichiers

## Demo rapide

Workflow minimal pour tester rapidement le POC :

```yaml
name: InstantRelease Demo

on:
  push:
    branches: [ main ]

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Run InstantRelease POC
        uses: ./poc-action
        with:
          generate-changelog: true
          create-tags: true
          dry-run: true
```

## Cas d'usage

- Projets open source qui veulent des releases propres sans effort
- Equipes produit qui publient souvent et veulent garder l'historique clair
- POCs et MVPs qui veulent un process simple, sans lourdeur

## Etat du projet

Le projet est en phase POC mais deja exploitable pour tester un workflow de release complet. Les prochaines evolutions sont listees dans `docs/ROADMAP.md`.

## Documentation

- Technique: `docs/TECHNICAL_DOCS.md`
- Roadmap: `docs/ROADMAP.md`

## Licence

Cette extension est gratuite pour un usage personnel, educatif ou non commercial.
Tout usage professionnel ou commercial est interdit sans autorisation ecrite de l'auteur.

Voir `LICENSE.md` pour les details.
Pour une licence pro: [vaxelaire.yohem@gmail.com](mailto:vaxelaire.yohem@gmail.com).

## Attribution

Si vous utilisez ce projet a titre personnel ou educatif, merci de le mentionner dans votre travail ou documentation.
