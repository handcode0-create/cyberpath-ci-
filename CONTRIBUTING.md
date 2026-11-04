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

Si tu modifies un fichier de `content/`, augmente son champ `version` (format `AAAA.MM.N`, par exemple `2026.11.3`). C'est ce qui déclenche la mise à jour dans l'app des utilisateurs.

### `methodology.json`, `tools.json`, `services.json` (piste Offensive)

Ces trois fichiers complètent la piste Offensive, au niveau éducatif, jamais opérationnel :

- `methodology.json` : les 7 phases d'un test d'intrusion (reconnaissance → rapport) et les étapes qui les couvrent.
- `tools.json` : un catalogue d'outils (quand les utiliser, quand ne pas les utiliser), avec une source officielle pour chacun — catalogue Kali ou dépôt d'origine, jamais une copie.
- `services.json` : une fiche par service qu'on rencontre après un scan (FTP, SSH, HTTP, SMB, RDP, MySQL…) : ce qu'il faut vérifier, quel outil d'énumération utiliser (et pourquoi), comment chercher les CVE de la version trouvée, vers quel lab légal s'entraîner.

Une fiche ne contient jamais de commande ou de recette d'attaque prête à lancer contre une cible : c'est la règle de fond du projet (voir « Éthique » dans le README). `tools/validate_content.py` vérifie que chaque `tool_id` cité dans `services.json` existe dans `tools.json`, et que chaque étape citée dans `methodology.json` existe dans `roadmap.json`.

## Contribuer au code

- Une pull request = un changement ciblé.
- `flutter analyze` et `flutter test` doivent passer.
- Respecte le thème existant (`app/lib/core/theme/`) plutôt que des couleurs en dur.

## Relecture

Le mainteneur relit chaque pull request. Les contributeurs réguliers peuvent devenir relecteurs du contenu.

En contribuant, tu acceptes que ton contenu soit publié sous CC BY-SA 4.0 et ton code sous MIT.
