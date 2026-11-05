import 'dart:convert';
import 'dart:io';

import 'package:cyberpath_ci/data/content_repository.dart';
import 'package:cyberpath_ci/data/models.dart';
import 'package:cyberpath_ci/data/progress_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FileBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = File(key).readAsBytesSync();
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }
}

String _asset(String name) => File('assets/content/$name').readAsStringSync();

Map<String, String> _unchangedExtras() => {
      'methodology.json': _asset('methodology.json'),
      'tools.json': _asset('tools.json'),
      'services.json': _asset('services.json'),
    };

String _bumped(String version) {
  final json = jsonDecode(_asset('roadmap.json')) as Map<String, dynamic>;
  json['version'] = version;
  return jsonEncode(json);
}

http.Client _server(Map<String, String> files) => MockClient((request) async {
      final name = request.url.pathSegments.last;
      final body = files[name];
      return body == null ? http.Response('absent', 404) : http.Response.bytes(utf8.encode(body), 200);
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('charge le contenu embarqué', () async {
    final repo = ContentRepository(await SharedPreferences.getInstance(), bundle: _FileBundle(), baseUrl: '');
    final content = await repo.load();
    expect(content.source, ContentSource.bundled);
    expect(content.roadmap.core.steps, hasLength(9));
    expect(repo.canUpdate, isFalse);
  });

  test('sans adresse configurée, la mise à jour est désactivée', () async {
    final repo = ContentRepository(await SharedPreferences.getInstance(), bundle: _FileBundle(), baseUrl: '');
    final result = await repo.checkForUpdate('2026.11.1');
    expect(result.status, UpdateStatus.notConfigured);
  });

  test('télécharge et garde une version plus récente', () async {
    final prefs = await SharedPreferences.getInstance();
    final client = _server({
      'roadmap.json': _bumped('2026.12.1'),
      'certifications.json': _asset('certifications.json'),
      'careers.json': _asset('careers.json'),
      ..._unchangedExtras(),
    });
    final repo = ContentRepository(prefs, bundle: _FileBundle(), client: client, baseUrl: 'https://exemple.test/content');

    final result = await repo.checkForUpdate('2026.11.1');
    expect(result.status, UpdateStatus.updated);
    expect(result.version, '2026.12.1');

    final content = await repo.load();
    expect(content.source, ContentSource.downloaded);
    expect(content.roadmap.version, '2026.12.1');
  });

  test('ignore une version identique', () async {
    final client = _server({
      'roadmap.json': _asset('roadmap.json'),
      'certifications.json': _asset('certifications.json'),
      'careers.json': _asset('careers.json'),
      ..._unchangedExtras(),
    });
    final repo = ContentRepository(await SharedPreferences.getInstance(),
        bundle: _FileBundle(), client: client, baseUrl: 'https://exemple.test/content');
    final result = await repo.checkForUpdate('2026.11.1');
    expect(result.status, UpdateStatus.upToDate);
  });

  test('garde la version actuelle si le téléchargement est abîmé', () async {
    final prefs = await SharedPreferences.getInstance();
    final client = _server({
      'roadmap.json': '{pas du json',
      'certifications.json': _asset('certifications.json'),
      'careers.json': _asset('careers.json'),
      ..._unchangedExtras(),
    });
    final repo = ContentRepository(prefs, bundle: _FileBundle(), client: client, baseUrl: 'https://exemple.test/content');
    final result = await repo.checkForUpdate('2026.11.1');
    expect(result.status, UpdateStatus.failed);
    expect((await repo.load()).source, ContentSource.bundled);
  });

  test('la progression et le profil restent sur le téléphone', () async {
    final store = ProgressStore(await SharedPreferences.getInstance());
    expect(store.onboarded, isFalse);
    await store.saveValidated({'tc-01': DateTime(2026, 11, 4)});
    await store.saveProfile(level: 'BTS2', goal: 'defensive', ethicsAccepted: true);
    expect(store.validated().keys, ['tc-01']);
    expect(store.level, 'BTS2');
    expect(store.goal, 'defensive');
    expect(store.onboarded, isTrue);
  });
}
