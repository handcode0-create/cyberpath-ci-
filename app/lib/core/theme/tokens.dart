import 'package:flutter/material.dart';

/// Couleurs du thème « Verre ». Les composants n'utilisent que ces rôles.
abstract final class CpColors {
  static const background = Color(0xFF0B0E12);
  static const primary = Color(0xFF34D1BF);
  static const primaryLight = Color(0xFF5EE6D3);
  static const primaryDeep = Color(0xFF1FA8C9);
  static const onPrimary = Color(0xFF06201C);
  static const indigo = Color(0xFF5468FF);

  static const text = Color(0xFFE8ECEF);
  static const textSecondary = Color(0xFFA7B0BA);
  static const textTertiary = Color(0xFF7F8A96);

  static const glass = Color(0x0BFFFFFF);
  static const glassRaised = Color(0x14FFFFFF);
  static const glassBorder = Color(0x17FFFFFF);
  static const glassHighlight = Color(0x0FFFFFFF);
  static const divider = Color(0x12FFFFFF);
  static const track = Color(0x14FFFFFF);
  static const lockedRing = Color(0xFF3A424C);

  /// Fond plein utilisé à la place du verre quand les effets sont réduits.
  static const solidSurface = Color(0xFF161A1F);
  static const solidNav = Color(0xF2121619);

  static const warning = Color(0xFFF2C14E);
  static const error = Color(0xFFFF6B6B);
  static const errorText = Color(0xFFFF8A8A);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary, primaryDeep],
    stops: [0, 0.45, 1],
  );

  static const progressGradient = LinearGradient(
    colors: [primaryDeep, primary, Color(0xFF7FF0E1)],
    stops: [0, 0.6, 1],
  );
}

/// Couleur de chaque spécialité. Toujours affichée avec son nom.
abstract final class CpTrackColors {
  static const defensive = Color(0xFF6AA8FF);
  static const offensive = Color(0xFFFF8A7A);
  static const forensic = Color(0xFFC3A1FF);
  static const grc = Color(0xFFF2C14E);

  static Color of(String id) => switch (id) {
        'defensive' => defensive,
        'offensive' => offensive,
        'forensic' => forensic,
        'grc' => grc,
        _ => CpColors.primary,
      };
}

/// Couleur du niveau pédagogique d'une ressource ou d'un lab.
abstract final class CpLevelColors {
  static Color of(String? level) => switch (level) {
        'debutant' => CpColors.primary,
        'intermediaire' => CpColors.warning,
        'avance' => CpColors.errorText,
        _ => CpColors.textTertiary,
      };
}

abstract final class CpRadius {
  static const tile = 10.0;
  static const button = 14.0;
  static const card = 16.0;
  static const cardLarge = 20.0;
  static const nav = 26.0;
  static const sheet = 28.0;
}

abstract final class CpSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const page = 20.0;

  /// Espace laissé sous le contenu pour la barre de navigation flottante.
  static const navClearance = 112.0;
}
