# Contribuer à CyberPath CI

Merci de vouloir aider. La plus grande partie de la valeur de l'app, c'est son contenu, et il s'améliore grâce aux étudiants, enseignants et professionnels qui le relisent.

## Ce que tu peux proposer

- **Une ressource** (cours, vidéo, doc, lab) pour une étape existante.
- **Un lien mort** ou une ressource devenue payante.
- **Une nouvelle étape** ou une correction dans une étape.
- **Du code** pour l'app Flutter.

Le plus simple pour commencer : ouvre une issue avec le modèle qui correspond.

## Règles pour les ressources

Une ressource est acceptée si :

1. elle est **gratuite**, ou propose un accès gratuit vraiment utile ;
2. elle est en **français ou en anglais** ;
3. elle est **légale** : les labs renvoient vers des environnements prévus pour ça, jamais vers un système réel ;
4. le lien est en **https**.

## Modifier `content/roadmap.json`

Chaque étape suit le format décrit dans `content/schema.json`. Exemple de ressource :

```json
{ "type": "cours", "title": "Nom de la ressource", "url": "https://...", "lang": "fr", "free": true }
```

Pour un lab, remplace `type` par `platform` (par exemple `"platform": "root-me"`).

Avant d'ouvrir ta pull request :

```bash
python3 tools/validate_content.py
python3 tools/sync_content.py
```

La CI refait ces vérifications et contrôle aussi que les liens répondent.

### Version du contenu

Si tu modifies `roadmap.json`, augmente le champ `version` (format `AAAA.MM.N`, par exemple `2026.11.2`). C'est ce qui déclenche la mise à jour dans l'app des utilisateurs.

## Contribuer au code

- Une pull request = un changement ciblé.
- `flutter analyze` et `flutter test` doivent passer.
- Respecte le thème existant (`app/lib/core/theme/`) plutôt que des couleurs en dur.

## Relecture

Le mainteneur relit chaque pull request. Les contributeurs réguliers peuvent devenir relecteurs du contenu.

En contribuant, tu acceptes que ton contenu soit publié sous CC BY-SA 4.0 et ton code sous MIT.
