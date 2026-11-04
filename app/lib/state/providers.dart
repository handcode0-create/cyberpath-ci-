import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/content_repository.dart';
import '../data/models.dart';
import '../data/progress_store.dart';

/// Remplacé dans main() par l'instance réelle.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider doit être surchargé'),
);

final progressStoreProvider = Provider<ProgressStore>(
  (ref) => ProgressStore(ref.watch(sharedPreferencesProvider)),
);

final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => ContentRepository(ref.watch(sharedPreferencesProvider)),
);

final contentProvider = FutureProvider<AppContent>(
  (ref) => ref.watch(contentRepositoryProvider).load(),
);

class ProgressNotifier extends Notifier<Map<String, DateTime>> {
  @override
  Map<String, DateTime> build() => ref.watch(progressStoreProvider).validated();

  Future<void> validate(String stepId) async {
    state = {...state, stepId: DateTime.now()};
    await ref.read(progressStoreProvider).saveValidated(state);
  }

  Future<void> unvalidate(String stepId) async {
    state = {...state}..remove(stepId);
    await ref.read(progressStoreProvider).saveValidated(state);
  }
}

final progressProvider =
    NotifierProvider<ProgressNotifier, Map<String, DateTime>>(ProgressNotifier.new);

class Profile {
  const Profile({
    required this.onboarded,
    required this.ethicsAccepted,
    this.level,
    this.goal,
  });

  final bool onboarded;
  final bool ethicsAccepted;
  final Level? level;

  /// Identifiant de spécialité, ou null si l'étudiant ne sait pas encore.
  final String? goal;
}

class ProfileNotifier extends Notifier<Profile> {
  @override
  Profile build() {
    final store = ref.watch(progressStoreProvider);
    return Profile(
      onboarded: store.onboarded,
      ethicsAccepted: store.ethicsAccepted,
      level: Level.fromCode(store.level),
      goal: store.goal,
    );
  }

  Future<void> save({required Level level, required String? goal}) async {
    await ref
        .read(progressStoreProvider)
        .saveProfile(level: level.code, goal: goal, ethicsAccepted: true);
    state = Profile(onboarded: true, ethicsAccepted: true, level: level, goal: goal);
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, Profile>(ProfileNotifier.new);

class ReduceEffectsNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(progressStoreProvider).reduceEffects;

  Future<void> set(bool value) async {
    state = value;
    await ref.read(progressStoreProvider).saveReduceEffects(value);
  }
}

final reduceEffectsProvider =
    NotifierProvider<ReduceEffectsNotifier, bool>(ReduceEffectsNotifier.new);
