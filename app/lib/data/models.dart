/// Modèles du contenu de CyberPath CI, lus depuis content/*.json.
library;

enum Level {
  bts1('BTS1', 'BTS 1re année', 'Tu démarres le tronc commun'),
  bts2('BTS2', 'BTS 2e année', 'Réseaux et Linux vus en cours'),
  l1('L1', 'Licence 1', 'Bases en programmation'),
  l2('L2', 'Licence 2', 'Les réseaux te parlent déjà'),
  l3('L3', 'Licence 3', 'Tu vises une spécialité'),
  auto('AUTO', 'Autodidacte', 'Hors cursus, en reconversion');

  const Level(this.code, this.label, this.hint);

  final String code;
  final String label;
  final String hint;

  static Level? fromCode(String? code) {
    for (final level in Level.values) {
      if (level.code == code) return level;
    }
    return null;
  }
}

class LinkItem {
  const LinkItem({
    required this.title,
    required this.url,
    required this.lang,
    required this.free,
    this.type,
    this.platform,
    this.level,
  });

  final String title;
  final String url;
  final String lang;
  final bool free;
  final String? type;
  final String? platform;

  /// « debutant », « intermediaire » ou « avance ». Indique par quoi
  /// commencer quand une étape propose plusieurs ressources ou labs.
  final String? level;

  bool get isLab => platform != null;

  String? get levelLabel => switch (level) {
        'debutant' => 'Débutant',
        'intermediaire' => 'Intermédiaire',
        'avance' => 'Avancé',
        _ => null,
      };

  factory LinkItem.fromJson(Map<String, dynamic> json) => LinkItem(
        title: json['title'] as String,
        url: json['url'] as String,
        lang: json['lang'] as String,
        free: json['free'] as bool,
        type: json['type'] as String?,
        platform: json['platform'] as String?,
        level: json['level'] as String?,
      );
}

class RoadmapStep {
  const RoadmapStep({
    required this.id,
    required this.code,
    required this.title,
    required this.summary,
    required this.durationWeeks,
    required this.skills,
    required this.requires,
    required this.resources,
    required this.labs,
    required this.validation,
    this.note,
    this.unlocks = const [],
  });

  final String id;
  final String code;
  final String title;
  final String summary;
  final int durationWeeks;
  final List<String> skills;
  final List<String> requires;
  final List<LinkItem> resources;
  final List<LinkItem> labs;
  final String validation;
  final String? note;
  final List<String> unlocks;

  factory RoadmapStep.fromJson(Map<String, dynamic> json) => RoadmapStep(
        id: json['id'] as String,
        code: json['code'] as String,
        title: json['title'] as String,
        summary: json['summary'] as String,
        durationWeeks: json['duration_weeks'] as int,
        skills: _strings(json['skills']),
        requires: _strings(json['requires']),
        resources: _links(json['resources']),
        labs: _links(json['labs']),
        validation: json['validation'] as String,
        note: json['note'] as String?,
        unlocks: _strings(json['unlocks']),
      );
}

class Track {
  const Track({
    required this.id,
    required this.title,
    required this.levels,
    required this.entryPoints,
    required this.steps,
  });

  final String id;
  final String title;
  final List<String> levels;
  final Map<String, String> entryPoints;
  final List<RoadmapStep> steps;

  RoadmapStep? step(String id) {
    for (final s in steps) {
      if (s.id == id) return s;
    }
    return null;
  }

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        id: json['id'] as String,
        title: json['title'] as String,
        levels: _strings(json['levels']),
        entryPoints: (json['entry_points'] as Map<String, dynamic>? ?? const {})
            .map((k, v) => MapEntry(k, v as String)),
        steps: (json['steps'] as List)
            .map((e) => RoadmapStep.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}

class Roadmap {
  const Roadmap({required this.version, required this.tracks, this.updated});

  static const coreTrackId = 'tronc-commun';

  final String version;
  final String? updated;
  final List<Track> tracks;

  Track get core => track(coreTrackId)!;

  Track? track(String id) {
    for (final t in tracks) {
      if (t.id == id) return t;
    }
    return null;
  }

  RoadmapStep? step(String id) {
    for (final t in tracks) {
      final s = t.step(id);
      if (s != null) return s;
    }
    return null;
  }

  factory Roadmap.fromJson(Map<String, dynamic> json) {
    final roadmap = Roadmap(
      version: json['version'] as String,
      updated: json['updated'] as String?,
      tracks: (json['tracks'] as List)
          .map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
    if (roadmap.track(coreTrackId) == null) {
      throw const FormatException('La piste tronc-commun est absente.');
    }
    return roadmap;
  }
}

class Certification {
  const Certification({
    required this.id,
    required this.title,
    required this.level,
    required this.tracks,
    required this.notes,
    required this.url,
    this.afterStep,
    this.priceUsd,
    this.checked,
  });

  final String id;
  final String title;
  final String level;
  final List<String> tracks;
  final String notes;
  final String url;
  final String? afterStep;
  final int? priceUsd;
  final String? checked;

  String get levelLabel => switch (level) {
        'debutant' => 'débutant',
        'intermediaire' => 'intermédiaire',
        'avance' => 'avancé',
        _ => level,
      };

  factory Certification.fromJson(Map<String, dynamic> json) => Certification(
        id: json['id'] as String,
        title: json['title'] as String,
        level: json['level'] as String,
        tracks: _strings(json['tracks']),
        notes: json['notes'] as String? ?? '',
        url: json['url'] as String,
        afterStep: json['after_step'] as String?,
        priceUsd: json['price_usd'] as int?,
        checked: json['checked'] as String?,
      );
}

class CertificationCatalog {
  const CertificationCatalog({required this.usdToXof, required this.items});

  final int usdToXof;
  final List<Certification> items;

  Certification? byId(String? id) {
    for (final c in items) {
      if (c.id == id) return c;
    }
    return null;
  }

  factory CertificationCatalog.fromJson(Map<String, dynamic> json) => CertificationCatalog(
        usdToXof: (json['currency_rate'] as Map<String, dynamic>?)?['usd_to_xof'] as int? ?? 600,
        items: (json['certifications'] as List)
            .map((e) => Certification.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}

class Specialty {
  const Specialty({
    required this.id,
    required this.title,
    required this.roles,
    required this.recruiters,
    this.certification,
  });

  final String id;
  final String title;
  final String roles;
  final String recruiters;
  final String? certification;

  factory Specialty.fromJson(Map<String, dynamic> json) => Specialty(
        id: json['id'] as String,
        title: json['title'] as String,
        roles: json['roles'] as String,
        recruiters: json['recruiters'] as String,
        certification: json['certification'] as String?,
      );
}

class Actor {
  const Actor({required this.name, required this.description});

  final String name;
  final String description;

  factory Actor.fromJson(Map<String, dynamic> json) =>
      Actor(name: json['name'] as String, description: json['description'] as String);
}

class Careers {
  const Careers({required this.specialties, required this.actors});

  final List<Specialty> specialties;
  final List<Actor> actors;

  Specialty? byId(String? id) {
    for (final s in specialties) {
      if (s.id == id) return s;
    }
    return null;
  }

  factory Careers.fromJson(Map<String, dynamic> json) => Careers(
        specialties: (json['specialties'] as List)
            .map((e) => Specialty.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        actors: (json['actors'] as List)
            .map((e) => Actor.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}

class PentestPhase {
  const PentestPhase({
    required this.id,
    required this.name,
    required this.goal,
    required this.question,
    required this.steps,
  });

  final String id;
  final String name;
  final String goal;
  final String question;
  final List<String> steps;

  factory PentestPhase.fromJson(Map<String, dynamic> json) => PentestPhase(
        id: json['id'] as String,
        name: json['name'] as String,
        goal: json['goal'] as String,
        question: json['question'] as String,
        steps: _strings(json['steps']),
      );
}

class AutomationNote {
  const AutomationNote({required this.title, required this.text, required this.steps});

  final String title;
  final String text;
  final List<String> steps;

  factory AutomationNote.fromJson(Map<String, dynamic> json) => AutomationNote(
        title: json['title'] as String,
        text: json['text'] as String,
        steps: _strings(json['steps']),
      );
}

class Methodology {
  const Methodology({
    required this.version,
    required this.title,
    required this.intro,
    required this.phases,
    this.automation,
  });

  final String version;
  final String title;
  final String intro;
  final List<PentestPhase> phases;
  final AutomationNote? automation;

  factory Methodology.fromJson(Map<String, dynamic> json) {
    final pentest = json['pentest'] as Map<String, dynamic>;
    return Methodology(
      version: json['version'] as String,
      title: pentest['title'] as String,
      intro: pentest['intro'] as String,
      phases: (pentest['phases'] as List)
          .map((e) => PentestPhase.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      automation: pentest['automation'] == null
          ? null
          : AutomationNote.fromJson(pentest['automation'] as Map<String, dynamic>),
    );
  }
}

class ToolSource {
  const ToolSource({required this.label, required this.url});

  final String label;
  final String url;

  factory ToolSource.fromJson(Map<String, dynamic> json) =>
      ToolSource(label: json['label'] as String, url: json['url'] as String);
}

class SecTool {
  const SecTool({
    required this.id,
    required this.name,
    required this.category,
    required this.purpose,
    required this.useWhen,
    required this.avoidWhen,
    required this.sources,
  });

  final String id;
  final String name;
  final String category;
  final String purpose;
  final String useWhen;
  final String avoidWhen;
  final List<ToolSource> sources;

  factory SecTool.fromJson(Map<String, dynamic> json) => SecTool(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        purpose: json['purpose'] as String,
        useWhen: json['use_when'] as String,
        avoidWhen: json['avoid_when'] as String,
        sources: (json['sources'] as List)
            .map((e) => ToolSource.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}

class ToolCategory {
  const ToolCategory({required this.id, required this.name});

  final String id;
  final String name;

  factory ToolCategory.fromJson(Map<String, dynamic> json) =>
      ToolCategory(id: json['id'] as String, name: json['name'] as String);
}

class ToolCatalog {
  const ToolCatalog({
    required this.version,
    required this.intro,
    required this.warning,
    required this.categories,
    required this.tools,
  });

  final String version;
  final String intro;
  final String warning;
  final List<ToolCategory> categories;
  final List<SecTool> tools;

  SecTool? byId(String id) {
    for (final t in tools) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<SecTool> byCategory(String categoryId) => tools.where((t) => t.category == categoryId).toList(growable: false);

  factory ToolCatalog.fromJson(Map<String, dynamic> json) => ToolCatalog(
        version: json['version'] as String,
        intro: json['intro'] as String,
        warning: json['warning'] as String,
        categories: (json['categories'] as List)
            .map((e) => ToolCategory.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        tools: (json['tools'] as List)
            .map((e) => SecTool.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}

class ServiceToolRef {
  const ServiceToolRef({required this.toolId, required this.why});

  final String toolId;
  final String why;

  factory ServiceToolRef.fromJson(Map<String, dynamic> json) =>
      ServiceToolRef(toolId: json['tool_id'] as String, why: json['why'] as String);
}

class LegalLab {
  const LegalLab({required this.platform, required this.title, required this.url});

  final String platform;
  final String title;
  final String url;

  factory LegalLab.fromJson(Map<String, dynamic> json) => LegalLab(
        platform: json['platform'] as String,
        title: json['title'] as String,
        url: json['url'] as String,
      );
}

class DiscoveredService {
  const DiscoveredService({
    required this.id,
    required this.name,
    required this.ports,
    required this.whatItIs,
    required this.checkFirst,
    required this.enumTools,
    required this.cveLookup,
    required this.legalLabs,
  });

  final String id;
  final String name;
  final String ports;
  final String whatItIs;
  final List<String> checkFirst;
  final List<ServiceToolRef> enumTools;
  final String cveLookup;
  final List<LegalLab> legalLabs;

  factory DiscoveredService.fromJson(Map<String, dynamic> json) => DiscoveredService(
        id: json['id'] as String,
        name: json['name'] as String,
        ports: json['ports'] as String,
        whatItIs: json['what_it_is'] as String,
        checkFirst: _strings(json['check_first']),
        enumTools: (json['enum_tools'] as List)
            .map((e) => ServiceToolRef.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        cveLookup: json['cve_lookup'] as String,
        legalLabs: (json['legal_labs'] as List)
            .map((e) => LegalLab.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}

class ServiceCatalog {
  const ServiceCatalog({required this.version, required this.intro, required this.services});

  final String version;
  final String intro;
  final List<DiscoveredService> services;

  factory ServiceCatalog.fromJson(Map<String, dynamic> json) => ServiceCatalog(
        version: json['version'] as String,
        intro: json['intro'] as String,
        services: (json['services'] as List)
            .map((e) => DiscoveredService.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}

enum ContentSource { bundled, downloaded }

class AppContent {
  const AppContent({
    required this.roadmap,
    required this.certifications,
    required this.careers,
    required this.methodology,
    required this.tools,
    required this.services,
    required this.source,
  });

  final Roadmap roadmap;
  final CertificationCatalog certifications;
  final Careers careers;
  final Methodology methodology;
  final ToolCatalog tools;
  final ServiceCatalog services;
  final ContentSource source;
}

List<String> _strings(Object? value) =>
    (value as List? ?? const []).map((e) => e as String).toList(growable: false);

List<LinkItem> _links(Object? value) => (value as List? ?? const [])
    .map((e) => LinkItem.fromJson(e as Map<String, dynamic>))
    .toList(growable: false);

/// Compare deux versions de contenu au format AAAA.MM.N.
/// Renvoie un nombre positif si [a] est plus récente que [b].
int compareContentVersions(String a, String b) {
  List<int> parts(String v) => v.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final pa = parts(a);
  final pb = parts(b);
  for (var i = 0; i < 3; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x - y;
  }
  return 0;
}
