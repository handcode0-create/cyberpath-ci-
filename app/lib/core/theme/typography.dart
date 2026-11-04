import 'package:flutter/material.dart';

import 'tokens.dart';

/// Les polices embarquées sont variables : on règle l'axe « wght »
/// en plus de fontWeight pour que la graisse s'applique partout.
TextStyle cpText(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = CpColors.text,
  double? lineHeight,
  double? letterSpacing,
  bool mono = false,
}) {
  return TextStyle(
    fontFamily: mono ? 'JetBrainsMono' : 'Inter',
    fontSize: size,
    fontWeight: weight,
    fontVariations: [FontVariation('wght', weight.value.toDouble())],
    fontFeatures: mono ? const [FontFeature.tabularFigures()] : null,
    color: color,
    height: lineHeight == null ? null : lineHeight / size,
    letterSpacing: letterSpacing,
  );
}

/// Échelle typographique du design system.
abstract final class CpType {
  static TextStyle display({Color color = CpColors.text}) =>
      cpText(28, weight: FontWeight.w700, lineHeight: 34, letterSpacing: -0.56, color: color);

  static TextStyle title1({Color color = CpColors.text}) =>
      cpText(24, weight: FontWeight.w700, lineHeight: 30, letterSpacing: -0.24, color: color);

  static TextStyle title2({Color color = CpColors.text}) =>
      cpText(17, weight: FontWeight.w600, lineHeight: 22, color: color);

  static TextStyle body({Color color = CpColors.text}) =>
      cpText(15, lineHeight: 22, color: color);

  static TextStyle bodyStrong({Color color = CpColors.text}) =>
      cpText(15, weight: FontWeight.w600, lineHeight: 22, color: color);

  static TextStyle caption({Color color = CpColors.textSecondary}) =>
      cpText(13, lineHeight: 18, color: color);

  static TextStyle small({Color color = CpColors.textSecondary}) =>
      cpText(12, lineHeight: 17, color: color);

  static TextStyle label({Color color = CpColors.primary}) =>
      cpText(11, weight: FontWeight.w600, letterSpacing: 0.9, color: color, mono: true);

  static TextStyle numeric(double size, {Color color = CpColors.primary}) =>
      cpText(size, weight: FontWeight.w600, color: color, mono: true);
}
