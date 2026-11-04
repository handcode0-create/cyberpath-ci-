# CyberPath CI

Application mobile **gratuite et open source** qui donne aux étudiants ivoiriens en cybersécurité, du BTS à la Licence 3, une roadmap claire : quoi apprendre, dans quel ordre, avec quels labs, pour viser quel métier.

L'app fonctionne **entièrement hors ligne**. Le contenu de la roadmap est un simple fichier JSON dans ce repo, que tout le monde peut enrichir.

## Ce que contient le repo

```
cyberpath-ci/
├── app/                    # application Flutter (Android d'abord)
├── content/                # la roadmap : c'est ici qu'on contribue
│   ├── roadmap.json        # pistes et étapes
│   ├── certifications.json # certifications, prix vérifiés
│   ├── careers.json        # métiers et acteurs en Côte d'Ivoire
│   └── schema.json         # schéma de validation de roadmap.json
├── tools/                  # scripts de validation et de synchronisation
└── .github/                # CI et modèles d'issues
```

## Contribuer au contenu

Pas besoin de savoir coder en Flutter. Une ressource à ajouter, un lien mort, une étape à proposer : tout se passe dans `content/`. Lis [CONTRIBUTING.md](CONTRIBUTING.md).

## Lancer l'app

Prérequis : Flutter (version stable) et un téléphone Android ou un émulateur.

```bash
cd app
flutter create . --platforms=android --org ci.cyberpath   # première fois seulement
flutter pub get
flutter run
```

La première commande génère le dossier `android/` sans toucher au code dans `lib/`.

### Mises à jour du contenu

L'app embarque le contenu de `app/assets/content/`. Pour qu'elle télécharge les nouvelles versions publiées sur GitHub, passe l'adresse du dossier `content/` brut au build :

```bash
flutter build apk --dart-define=CONTENT_BASE_URL=https://raw.githubusercontent.com/<compte>/cyberpath-ci/main/content
```

Sans cette option, l'app reste sur le contenu embarqué et l'écran Plus l'indique.

Ajoute aussi `--dart-define=REPO_URL=https://github.com/<compte>/cyberpath-ci` pour afficher le lien « Contribuer sur GitHub » dans l'app.

### Architecture de l'app

```
app/lib/
├── core/        thème « Verre » (tokens, typo), composants, liens externes
├── data/        modèles, chargement du contenu, progression locale
├── domain/      logique du parcours (statuts des étapes, déblocages)
├── state/       providers Riverpod
└── features/    onboarding, parcours, fiche d'étape, métiers, certifs, plus
```

Le réglage « Réduire les effets » (écran Plus) coupe le flou et les lueurs ; il s'active aussi tout seul quand le téléphone demande de réduire les animations.

### Tests

```bash
cd app && flutter test
```

### Après avoir modifié `content/`

```bash
python3 tools/sync_content.py        # copie content/ vers app/assets/content/
python3 tools/validate_content.py    # schéma et cohérence
```

## Licences

- Code : [MIT](LICENSE)
- Contenu de la roadmap (`content/`) : [CC BY-SA 4.0](LICENSE-CONTENT)

## Éthique

CyberPath CI ne contient aucun outil offensif et ne renvoie que vers des plateformes d'entraînement légales. Pratiquer sur un système sans autorisation est puni par la loi ivoirienne.

---

Porté par [handCode Studio](https://handcode.site), Abidjan.
