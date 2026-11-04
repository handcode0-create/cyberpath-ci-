import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/glass.dart';
import '../../data/models.dart';
import '../parcours/step_detail_screen.dart';

/// Vue d'ensemble de la démarche d'un test d'intrusion, phase par phase,
/// avec un renvoi vers les étapes de la piste Offensive qui la couvrent.
class MethodeScreen extends StatelessWidget {
  const MethodeScreen({super.key, required this.content});

  final AppContent content;

  @override
  Widget build(BuildContext context) {
    final methodology = content.methodology;
    return Scaffold(
      body: AmbientBackground(
        topColor: CpTrackColors.offensive,
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(CpSpace.page, CpSpace.lg, CpSpace.page, CpSpace.xxl),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Retour',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.chevron_left, color: CpColors.text),
                  ),
                  const Spacer(),
                  Text('OFFENSIVE · MÉTHODE', style: CpType.label(color: CpTrackColors.offensive)),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: CpSpace.md),
              Semantics(header: true, child: Text(methodology.title, style: CpType.title1())),
              const SizedBox(height: CpSpace.sm),
              Text(methodology.intro, style: CpType.body(color: CpColors.textSecondary)),
              const SizedBox(height: CpSpace.xxl),
              for (var i = 0; i < methodology.phases.length; i++) ...[
                _PhaseCard(index: i + 1, phase: methodology.phases[i], content: content),
                if (i < methodology.phases.length - 1) _Connector(),
              ],
              if (methodology.automation != null) ...[
                const SizedBox(height: CpSpace.lg),
                _AutomationCard(automation: methodology.automation!, content: content),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 19, top: 2, bottom: 2),
      child: Container(width: 2, height: CpSpace.lg, color: CpColors.glassBorder),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({required this.index, required this.phase, required this.content});

  final int index;
  final PentestPhase phase;
  final AppContent content;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CpTrackColors.offensive.withValues(alpha: 0.16),
              border: Border.all(color: CpTrackColors.offensive.withValues(alpha: 0.6)),
            ),
            child: Text('$index', style: cpText(15, weight: FontWeight.w700, color: CpTrackColors.offensive)),
          ),
          const SizedBox(width: CpSpace.lg),
          Expanded(
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(phase.name, style: CpType.title2()),
                  const SizedBox(height: CpSpace.xs),
                  Text(phase.goal, style: CpType.body(color: CpColors.textSecondary)),
                  const SizedBox(height: CpSpace.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.help_outline, size: 15, color: CpColors.textTertiary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          phase.question,
                          style: cpText(13, color: CpColors.textTertiary, lineHeight: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: CpSpace.md),
                  Wrap(
                    spacing: CpSpace.sm,
                    runSpacing: CpSpace.sm,
                    children: [
                      for (final sid in phase.steps)
                        if (content.roadmap.step(sid) != null) _StepLink(stepId: sid, content: content),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepLink extends StatelessWidget {
  const _StepLink({required this.stepId, required this.content});

  final String stepId;
  final AppContent content;

  @override
  Widget build(BuildContext context) {
    final step = content.roadmap.step(stepId)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => StepDetailScreen(content: content, trackId: 'offensive', stepId: stepId),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            color: CpColors.glass,
            border: Border.all(color: CpColors.glassBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${step.code} · ${step.title}', style: cpText(13, weight: FontWeight.w500)),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward, size: 13, color: CpColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _AutomationCard extends StatelessWidget {
  const _AutomationCard({required this.automation, required this.content});

  final AutomationNote automation;
  final AppContent content;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      accent: CpColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 18, color: CpColors.primary),
              const SizedBox(width: CpSpace.sm),
              Text(automation.title, style: CpType.title2()),
            ],
          ),
          const SizedBox(height: CpSpace.sm),
          Text(automation.text, style: CpType.body(color: CpColors.textSecondary)),
          const SizedBox(height: CpSpace.md),
          Wrap(
            spacing: CpSpace.sm,
            runSpacing: CpSpace.sm,
            children: [
              for (final sid in automation.steps)
                if (content.roadmap.step(sid) != null) _StepLink(stepId: sid, content: content),
            ],
          ),
        ],
      ),
    );
  }
}
