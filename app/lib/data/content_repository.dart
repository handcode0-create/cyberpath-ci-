import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Adresse du dossier content/ brut sur GitHub, passée au build avec
/// --dart-define=CONTENT_BASE_URL=... Vide : pas de mise à jour en ligne.
const contentBaseUrl = String.fromEnvironment('CONTENT_BASE_URL');

const _files = ['roadmap.json', 'certifications.json', 'careers.json'];
const _cachePrefix = 'content.cache.';

enum UpdateStatus { updated, upToDate, notConfigured, failed }

class UpdateResult {
  const UpdateResult(this.status, {this.version});

  final UpdateStatus status;
  final String? version;
}

/// Charge le contenu embarqué, ou la version téléchargée si elle est plus récente.
class ContentRepository {
  ContentRepository(
    this._prefs, {
    AssetBundle? bundle,
    http.Client? client,
    String baseUrl = contentBaseUrl,
  })  : _bundle = bundle ?? rootBundle,
        _client = client ?? http.Client(),
        _baseUrl = baseUrl;

  final SharedPreferences _prefs;
  final AssetBundle _bundle;
  final http.Client _client;
  final String _baseUrl;

  bool get canUpdate => _baseUrl.isNotEmpty;

  Future<AppContent> load() async {
    final bundled = parse(
      {for (final f in _files) f: await _bundle.loadString('assets/content/$f')},
      ContentSource.bundled,
    );
    final cached = _readCache();
    if (cached != null &&
        compareContentVersions(cached.roadmap.version, bundled.roadmap.version) > 0) {
      return cached;
    }
    return bundled;
  }

  /// Télécharge le contenu publié et le garde s'il est plus récent que [currentVersion].
  Future<UpdateResult> checkForUpdate(String currentVersion) async {
    if (!canUpdate) return const UpdateResult(UpdateStatus.notConfigured);
    try {
      final raw = <String, String>{};
      for (final f in _files) {
        final response = await _client
            .get(Uri.parse('$_baseUrl/$f'))
            .timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) {
          return const UpdateResult(UpdateStatus.failed);
        }
        raw[f] = utf8.decode(response.bodyBytes);
      }
      final remote = parse(raw, ContentSource.downloaded);
      if (compareContentVersions(remote.roadmap.version, currentVersion) <= 0) {
        return UpdateResult(UpdateStatus.upToDate, version: currentVersion);
      }
      for (final entry in raw.entries) {
        await _prefs.setString('$_cachePrefix${entry.key}', entry.value);
      }
      return UpdateResult(UpdateStatus.updated, version: remote.roadmap.version);
    } catch (_) {
      return const UpdateResult(UpdateStatus.failed);
    }
  }

  AppContent? _readCache() {
    final raw = <String, String>{};
    for (final f in _files) {
      final value = _prefs.getString('$_cachePrefix$f');
      if (value == null) return null;
      raw[f] = value;
    }
    try {
      return parse(raw, ContentSource.downloaded);
    } catch (_) {
      return null;
    }
  }

  static AppContent parse(Map<String, String> raw, ContentSource source) {
    Map<String, dynamic> decode(String name) =>
        jsonDecode(raw[name]!) as Map<String, dynamic>;
    return AppContent(
      roadmap: Roadmap.fromJson(decode('roadmap.json')),
      certifications: CertificationCatalog.fromJson(decode('certifications.json')),
      careers: Careers.fromJson(decode('careers.json')),
      source: source,
    );
  }
}
