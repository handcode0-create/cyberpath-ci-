import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../theme/tokens.dart';

/// Vrai quand l'étudiant a demandé moins d'effets, ou que le téléphone
/// demande de réduire les animations.
bool effectsReduced(BuildContext context, WidgetRef ref) =>
    ref.watch(reduceEffectsProvider) || MediaQuery.of(context).disableAnimations;

/// Fond de l'app : deux halos diffus, Lagune et indigo, qui donnent au verre
/// quelque chose à flouter.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({
    super.key,
    required this.child,
    this.topColor = CpColors.primary,
    this.bottomColor = CpColors.indigo,
  });

  final Widget child;
  final Color topColor;
  final Color bottomColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: CpColors.background),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(1.0, -1.0),
                  radius: 1.1,
                  colors: [topColor.withValues(alpha: 0.26), topColor.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-1.0, 1.0),
                  radius: 1.2,
                  colors: [bottomColor.withValues(alpha: 0.2), bottomColor.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Surface en verre. Le vrai flou ([blur]) coûte cher sur les petits
/// téléphones : on le réserve à la navigation et aux feuilles.
class GlassCard extends ConsumerWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(CpSpace.lg),
    this.radius = CpRadius.card,
    this.accent,
    this.blur = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Teinte et bordure colorées pour une carte mise en avant.
  final Color? accent;
  final bool blur;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduced = effectsReduced(context, ref);
    final shape = BorderRadius.circular(radius);
    final accent = this.accent;

    final decoration = BoxDecoration(
      borderRadius: shape,
      color: reduced ? CpColors.solidSurface : (accent == null ? CpColors.glass : null),
      gradient: !reduced && accent != null
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent.withValues(alpha: 0.16), CpColors.glass],
              stops: const [0, 0.6],
            )
          : null,
      border: Border.all(
        color: accent == null ? CpColors.glassBorder : accent.withValues(alpha: 0.55),
      ),
      boxShadow: !reduced && accent != null
          ? [BoxShadow(color: accent.withValues(alpha: 0.16), blurRadius: 40, offset: const Offset(0, 12))]
          : null,
    );

    Widget content = DecoratedBox(
      decoration: decoration,
      child: Padding(padding: padding, child: child),
    );

    if (blur && !reduced) {
      content = ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: content,
        ),
      );
    }
    return content;
  }
}
