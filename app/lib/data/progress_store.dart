import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Tout ce que l'app garde sur le téléphone. Aucune donnée ne quitte l'appareil.
class ProgressStore {
  ProgressStore(this._prefs);

  final SharedPreferences _prefs;

  static const _validatedKey = 'progress.validated';
  static const _levelKey = 'profile.level';
  static const _goalKey = 'profile.goal';
  static const _onboardedKey = 'profile.onboarded';
  static const _ethicsKey = 'profile.ethicsAccepted';
  static const _reduceEffectsKey = 'settings.reduceEffects';

  Map<String, DateTime> validated() {
    final raw = _prefs.getString(_validatedKey);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, DateTime.parse(v as String)));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveValidated(Map<String, DateTime> value) => _prefs.setString(
        _validatedKey,
        jsonEncode(value.map((k, v) => MapEntry(k, v.toIso8601String()))),
      );

  String? get level => _prefs.getString(_levelKey);
  String? get goal => _prefs.getString(_goalKey);
  bool get onboarded => _prefs.getBool(_onboardedKey) ?? false;
  bool get ethicsAccepted => _prefs.getBool(_ethicsKey) ?? false;
  bool get reduceEffects => _prefs.getBool(_reduceEffectsKey) ?? false;

  Future<void> saveProfile({
    required String level,
    required String? goal,
    required bool ethicsAccepted,
  }) async {
    await _prefs.setString(_levelKey, level);
    if (goal == null) {
      await _prefs.remove(_goalKey);
    } else {
      await _prefs.setString(_goalKey, goal);
    }
    await _prefs.setBool(_ethicsKey, ethicsAccepted);
    await _prefs.setBool(_onboardedKey, true);
  }

  Future<void> saveReduceEffects(bool value) => _prefs.setBool(_reduceEffectsKey, value);
}
