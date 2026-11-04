import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Adresse du repo GitHub, passée au build avec --dart-define=REPO_URL=...
const repoUrl = String.fromEnvironment('REPO_URL');

/// Ouvre un lien externe dans le navigateur, avec un message clair en cas d'échec.
Future<void> openExternal(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  final uri = Uri.tryParse(url);
  var opened = false;
  if (uri != null) {
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
  }
  if (!opened) {
    messenger.showSnackBar(
      const SnackBar(content: Text("Impossible d'ouvrir le lien. Vérifie ta connexion puis réessaie.")),
    );
  }
}
