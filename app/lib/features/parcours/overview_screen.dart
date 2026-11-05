import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/step_node.dart';
import '../../data/models.dart';
import '../../domain/roadmap_logic.dart';
import '../../state/providers.dart';
import 'step_detail_screen.dart';

/// Vue d'ensemble de tout le parcours : le tronc commun puis les quatre
/// spécialités, dans l'ordre, sur un seul écran — pour voir la suite
/// logique sans naviguer piste par piste.
class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key, required this.content});

  final AppContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roadmap = content.roadmap;
    final validated = ref.watch(progressProvider);
    final profile = ref.watch(profileProvider);
    final unlocked = unlockedSpecialties(roadmap, validated);
    final coreView = buildTrackView(roadmap.core, validated, profile.level);
    final specialties = content.careers.specialties;

    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(CpSpace.page, CpSpace.md, CpSpace.page, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Retour au parcours',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.chevron_left, color: CpColors.text),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text("Vue d'ensemble", style: CpType.title1()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(CpSpace.page, CpSpace.sm, CpSpace.page, 0),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    "Tout le parcours, dans l'ordre : le tronc commun d'abord, "
                    'puis les quatre spécialités qu\'il débloque.',
                    style: CpType.body(color: CpColors.textSecondary),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(CpSpace.page, CpSpace.xl, CpSpace.page, 0),
                sliver: SliverToBoxAdapter(
                  child: _TrackSection(
                    title: 'Tronc commun',
                    color: CpColors.primary,
                    view: coreView,
                    onOpenStep: (stepId) => _openStep(context, roadmap.core.id, stepId),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(CpSpace.page, CpSpace.lg, CpSpace.page, 0),
                sliver: SliverToBoxAdapter(
                  child: _BranchNotice(unlocked: unlocked.isNotEmpty),
                ),
              ),
              for (final specialty in specialties)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(CpSpace.page, CpSpace.lg, CpSpace.page, 0),
                  sliver: SliverToBoxAdapter(
                    child: unlocked.contains(specialty.id)
                        ? _TrackSection(
                            title: specialty.title,
                            color: CpTrackColors.of(specialty.id),
                            view: buildTrackView(roadmap.track(specialty.id)!, validated, null),
                            onOpenStep: (stepId) => _openStep(context, specialty.id, stepId),
                          )
                        : _LockedTrackSection(
                            title: specialty.title,
                            color: CpTrackColors.of(specialty.id),
                            stepCount: roadmap.track(specialty.id)?.steps.length ?? 0,
                          ),
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: CpSpace.xxl)),
            ],
          ),
        ),
      ),
    );
  }

  void _openStep(BuildContext context, String trackId, String stepId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StepDetailScreen(content: content, trackId: trackId, stepId: stepId),
      ),
    );
  }
}

class _BranchNotice extends StatelessWidget {
  const _BranchNotice({required this.unlocked});

  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          unlocked ? Icons.call_split : Icons.lock_outline,
          size: 16,
          color: CpColors.textTertiary,
        ),
        const SizedBox(width: CpSpace.sm),
        Expanded(
          child: Text(
            unlocked
                ? 'Le tronc commun se termine ici. Quatre chemins possibles ensuite :'
                : "Le tronc commun débloque les quatre spécialités ci-dessous une fois terminé.",
            style: CpType.caption(),
          ),
        ),
      ],
    );
  }
}

class _TrackSection extends StatelessWidget {
  const _TrackSection({
    required this.title,
    required this.color,
    required this.view,
    required this.onOpenStep,
  });

  final String title;
  final Color color;
  final TrackView view;
  final void Function(String stepId) onOpenStep;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(CpSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: CpSpace.sm),
              Expanded(child: Text(title.toUpperCase(), style: CpType.label(color: color))),
              Text('${view.done}/${view.total}', style: CpType.caption()),
            ],
          ),
          const SizedBox(height: CpSpace.sm),
          for (final s in view.steps) _OverviewStepRow(view: s, onTap: () => onOpenStep(s.step.id)),
        ],
      ),
    );
  }
}

class _OverviewStepRow extends StatelessWidget {
  const _OverviewStepRow({required this.view, required this.onTap});

  final StepView view;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = view.isDone;
    return Semantics(
      button: true,
      label: '${view.step.code} ${view.step.title}, ${statusLabel(view.status)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CpRadius.tile),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              StepNode(status: view.status),
              const SizedBox(width: CpSpace.md),
              Expanded(
                child: Text(
                  '${view.step.code} · ${view.step.title}',
                  style: cpText(14, weight: FontWeight.w500, color: muted ? CpColors.textSecondary : CpColors.text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedTrackSection extends StatelessWidget {
  const _LockedTrackSection({required this.title, required this.color, required this.stepCount});

  final String title;
  final Color color;
  final int stepCount;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(CpSpace.md),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.4)),
          ),
          const SizedBox(width: CpSpace.sm),
          Expanded(
            child: Text(
              '${title.toUpperCase()} · $stepCount étapes',
              style: CpType.label(color: CpColors.textTertiary),
            ),
          ),
          const Icon(Icons.lock_outline, size: 16, color: CpColors.textTertiary),
        ],
      ),
    );
  }
}
