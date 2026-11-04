import 'dart:io';

import 'package:cyberpath_ci/data/content_repository.dart';
import 'package:cyberpath_ci/data/models.dart';
import 'package:cyberpath_ci/domain/roadmap_logic.dart';
import 'package:flutter_test/flutter_test.dart';

const _contentFiles = [
  'roadmap.json',
  'certifications.json',
  'careers.json',
  'methodology.json',
  'tools.json',
  'services.json',
];

AppContent loadContent() => ContentRepository.parse(
      {for (final f in _contentFiles) f: File('assets/content/$f').readAsStringSync()},
      ContentSource.bundled,
    );

void main() {
  final content = loadContent();
  final core = content.roadmap.core;

  group('contenu embarqué', () {
    test('le tronc commun a 9 étapes reliées par des prérequis existants', () {
      expect(core.steps, hasLength(9));
      final ids = core.steps.map((s) => s.id).toSet();
      for (final step in core.steps) {
        expect(ids.containsAll(step.requires), isTrue, reason: step.id);
      }
    });

    test('chaque niveau a un point de départ', () {
      for (final level in Level.values) {
        expect(core.entryPoints[level.code], isNotNull, reason: level.code);
      }
    });

    test('le bilan débloque les 4 spécialités', () {
      expect(core.step('tc-09')!.unlocks, containsAll(['defensive', 'offensive', 'forensic', 'grc']));
    });
  });

  group('statuts des étapes', () {
    test('un débutant commence à la première étape, le reste est verrouillé', () {
      final view = buildTrackView(core, {}, Level.bts1);
      expect(view.current!.step.id, 'tc-01');
      expect(view.viewOf('tc-02').status, StepStatus.locked);
      expect(view.done, 0);
    });

    test("le niveau BTS 2 part de l'étape 3 avec les précédentes acquises", () {
      final view = buildTrackView(core, {}, Level.bts2);
      expect(view.viewOf('tc-01').status, StepStatus.acquired);
      expect(view.viewOf('tc-02').status, StepStatus.acquired);
      expect(view.current!.step.id, 'tc-03');
      expect(view.done, 2);
    });

    test('valider une étape ouvre la suivante', () {
      final view = buildTrackView(core, {'tc-01': DateTime(2026, 11, 4)}, Level.bts1);
      expect(view.viewOf('tc-01').status, StepStatus.validated);
      expect(view.current!.step.id, 'tc-02');
    });

    test('plusieurs étapes peuvent être ouvertes en même temps', () {
      final validated = {'tc-01': DateTime(2026), 'tc-02': DateTime(2026)};
      final view = buildTrackView(core, validated, Level.bts1);
      expect(view.viewOf('tc-03').status, StepStatus.current);
      expect(view.viewOf('tc-05').status, StepStatus.available);
    });

    test('stepsUnlockedBy annonce ce que la validation va ouvrir', () {
      final opened = stepsUnlockedBy(core, 'tc-02', {'tc-01': DateTime(2026)}, Level.bts1);
      expect(opened.map((s) => s.id), containsAll(['tc-03', 'tc-05']));
    });

    test('les spécialités ne sont ouvertes qu\'après le bilan', () {
      expect(unlockedSpecialties(content.roadmap, {}), isEmpty);
      expect(
        unlockedSpecialties(content.roadmap, {'tc-09': DateTime(2026)}),
        {'defensive', 'offensive', 'forensic', 'grc'},
      );
    });
  });

  group('spécialités', () {
    test('chaque spécialité de careers.json a sa piste', () {
      for (final specialty in content.careers.specialties) {
        final track = content.roadmap.track(specialty.id);
        expect(track, isNotNull, reason: specialty.id);
        expect(track!.steps, isNotEmpty, reason: specialty.id);
      }
    });

    test('une piste de spécialité démarre à sa première étape', () {
      final defensive = content.roadmap.track('defensive')!;
      final view = buildTrackView(defensive, {}, null);
      expect(view.current!.step.id, 'def-01');
      expect(view.viewOf('def-02').status, StepStatus.locked);
    });

    test('la piste Offensive suit la méthode : recon, énum, vuln, exploit, postexploit, auto, rapport', () {
      final offensive = content.roadmap.track('offensive')!;
      expect(offensive.steps.map((s) => s.id), [
        'off-01', 'off-02', 'off-03', 'off-04', 'off-05', 'off-06', 'off-07', 'off-08',
      ]);
      final ids = offensive.steps.map((s) => s.id).toSet();
      for (final phase in content.methodology.phases) {
        for (final sid in phase.steps) {
          expect(ids.contains(sid), isTrue, reason: '${phase.id} -> $sid');
        }
      }
    });

    test('les certifications citées par les métiers existent', () {
      for (final specialty in content.careers.specialties) {
        if (specialty.certification != null) {
          expect(content.certifications.byId(specialty.certification), isNotNull);
        }
      }
    });
  });

  group('boîte à outils et services', () {
    test('chaque outil référencé par une fiche service existe dans le catalogue', () {
      final toolIds = content.tools.tools.map((t) => t.id).toSet();
      for (final service in content.services.services) {
        for (final ref in service.enumTools) {
          expect(toolIds.contains(ref.toolId), isTrue, reason: '${service.id} -> ${ref.toolId}');
        }
      }
    });

    test('chaque outil appartient à une catégorie déclarée', () {
      final catIds = content.tools.categories.map((c) => c.id).toSet();
      for (final tool in content.tools.tools) {
        expect(catIds.contains(tool.category), isTrue, reason: tool.id);
      }
    });

    test('byCategory et byId retrouvent les bons outils', () {
      final nmap = content.tools.byId('nmap');
      expect(nmap, isNotNull);
      expect(content.tools.byCategory('scan'), contains(nmap));
    });
  });

  group('utilitaires', () {
    test('comparaison de versions de contenu', () {
      expect(compareContentVersions('2026.11.2', '2026.11.1'), greaterThan(0));
      expect(compareContentVersions('2026.9.1', '2026.11.1'), lessThan(0));
      expect(compareContentVersions('2026.11.1', '2026.11.1'), 0);
    });

    test('format FCFA arrondi', () {
      expect(formatXof(roundToThousand(199 * 600)), '120 000');
      expect(formatXof(roundToThousand(439 * 600)), '263 000');
    });

    test('date courte en français', () {
      expect(formatShortDate(DateTime(2026, 10, 21)), '21 oct.');
    });
  });
}
