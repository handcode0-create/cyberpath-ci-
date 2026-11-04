import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/roadmap_logic.dart';
import '../theme/tokens.dart';
import 'glass.dart';

/// Pastille d'étape sur la ligne du parcours.
class StepNode extends ConsumerWidget {
  const StepNode({super.key, required this.status});

  final StepStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduced = effectsReduced(context, ref);
    switch (status) {
      case StepStatus.validated:
      case StepStatus.acquired:
        final validated = status == StepStatus.validated;
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: validated ? CpColors.primary : CpColors.primary.withValues(alpha: 0.18),
            border: validated ? null : Border.all(color: CpColors.primary.withValues(alpha: 0.5)),
            boxShadow: validated && !reduced
                ? [BoxShadow(color: CpColors.primary.withValues(alpha: 0.5), blurRadius: 14)]
                : null,
          ),
          child: Icon(Icons.check_rounded, size: 15, color: validated ? CpColors.onPrimary : CpColors.primary),
        );
      case StepStatus.current:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: CpColors.primary, width: 2),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: CpColors.primary),
          ),
        );
      case StepStatus.available:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: CpColors.primary.withValues(alpha: 0.6), width: 1.5),
          ),
        );
      case StepStatus.locked:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: CpColors.lockedRing, width: 1.5),
          ),
          child: const Icon(Icons.lock_outline, size: 12, color: CpColors.textTertiary),
        );
    }
  }
}

/// Libellé accessible d'un état d'étape.
String statusLabel(StepStatus status) => switch (status) {
      StepStatus.validated => 'validée',
      StepStatus.acquired => 'acquise avec ton niveau',
      StepStatus.current => 'en cours',
      StepStatus.available => 'ouverte',
      StepStatus.locked => 'verrouillée',
    };
