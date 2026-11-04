import '../data/models.dart';

/// État d'une étape pour un étudiant donné.
enum StepStatus {
  /// Validée par l'étudiant.
  validated,

  /// Avant son point de départ : considérée comme acquise par son niveau.
  acquired,

  /// La prochaine étape à travailler.
  current,

  /// Ouverte, mais pas la prochaine dans l'ordre.
  available,

  /// Un prérequis manque encore.
  locked,
}

class StepView {
  const StepView({
    required this.step,
    required this.index,
    required this.status,
    this.validatedAt,
  });

  final RoadmapStep step;
  final int index;
  final StepStatus status;
  final DateTime? validatedAt;

  bool get isDone => status == StepStatus.validated || status == StepStatus.acquired;
  bool get isOpen => status == StepStatus.current || status == StepStatus.available;
}

class TrackView {
  const TrackView({required this.track, required this.steps});

  final Track track;
  final List<StepView> steps;

  int get total => steps.length;
  int get done => steps.where((s) => s.isDone).length;
  double get ratio => total == 0 ? 0 : done / total;
  int get percent => (ratio * 100).round();
  bool get completed => total > 0 && done == total;

  StepView? get current {
    for (final s in steps) {
      if (s.status == StepStatus.current) return s;
    }
    return null;
  }

  StepView viewOf(String stepId) => steps.firstWhere((s) => s.step.id == stepId);
}

/// Calcule l'état de chaque étape d'une piste.
///
/// Les étapes placées avant le point d'entrée du niveau sont « acquises » :
/// elles satisfont les prérequis sans compter comme validées.
TrackView buildTrackView(Track track, Map<String, DateTime> validated, Level? level) {
  final position = {for (var i = 0; i < track.steps.length; i++) track.steps[i].id: i};
  var entry = 0;
  final entryId = level == null ? null : track.entryPoints[level.code];
  if (entryId != null && position.containsKey(entryId)) entry = position[entryId]!;

  bool satisfied(String id) {
    final i = position[id];
    if (i == null) return false;
    return validated.containsKey(id) || i < entry;
  }

  final statuses = <StepStatus>[];
  for (var i = 0; i < track.steps.length; i++) {
    final step = track.steps[i];
    if (validated.containsKey(step.id)) {
      statuses.add(StepStatus.validated);
    } else if (i < entry) {
      statuses.add(StepStatus.acquired);
    } else if (step.requires.every(satisfied)) {
      statuses.add(StepStatus.available);
    } else {
      statuses.add(StepStatus.locked);
    }
  }

  final currentIndex = statuses.indexOf(StepStatus.available);
  if (currentIndex >= 0) statuses[currentIndex] = StepStatus.current;

  return TrackView(
    track: track,
    steps: [
      for (var i = 0; i < track.steps.length; i++)
        StepView(
          step: track.steps[i],
          index: i,
          status: statuses[i],
          validatedAt: validated[track.steps[i].id],
        ),
    ],
  );
}

/// Les spécialités s'ouvrent quand l'étape qui les débloque est validée.
Set<String> unlockedSpecialties(Roadmap roadmap, Map<String, DateTime> validated) {
  final unlocked = <String>{};
  for (final step in roadmap.core.steps) {
    if (validated.containsKey(step.id)) unlocked.addAll(step.unlocks);
  }
  return unlocked;
}

/// Étapes qui s'ouvrent si [stepId] est validée maintenant.
List<RoadmapStep> stepsUnlockedBy(
  Track track,
  String stepId,
  Map<String, DateTime> validated,
  Level? level,
) {
  final before = buildTrackView(track, validated, level);
  final after = buildTrackView(track, {...validated, stepId: DateTime.now()}, level);
  return [
    for (var i = 0; i < before.steps.length; i++)
      if (before.steps[i].status == StepStatus.locked && after.steps[i].isOpen)
        after.steps[i].step,
  ];
}

const _months = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

String formatShortDate(DateTime date) => '${date.day} ${_months[date.month - 1]}';

String formatXof(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Arrondit au millier pour un prix indicatif en FCFA.
int roundToThousand(int value) => ((value + 500) ~/ 1000) * 1000;
