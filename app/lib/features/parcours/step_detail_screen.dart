import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/links.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/glass.dart';
import '../../data/models.dart';
import '../../domain/roadmap_logic.dart';
import '../../state/providers.dart';
import 'step_validated_screen.dart';

class StepDetailScreen extends ConsumerWidget {
  const StepDetailScreen({
    super.key,
    required this.content,
    required this.trackId,
    required this.stepId,
  });

  final AppContent content;
  final String trackId;
  final String stepId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = content.roadmap.track(trackId)!;
    final validated = ref.watch(progressProvider);
    final profile = ref.watch(profileProvider);
    final level = trackId == Roadmap.coreTrackId ? profile.level : null;
    final trackView = buildTrackView(track, validated, level);
    final view = trackView.viewOf(stepId);
    final step = view.step;
    final links = [...step.resources, ...step.labs];

    return Scaffold(
      body: AmbientBackground(
        child: Column(
          children: [
            Expanded(
              child: SafeArea(
                bottom: false,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(CpSpace.page, 0, CpSpace.page, CpSpace.xxl),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Retour au parcours',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.chevron_left, color: CpColors.text),
                        ),
                        const Spacer(),
                        Text(
                          '${track.title.toUpperCase()} · ${view.index + 1} / ${track.steps.length}',
                          style: CpType.label(color: CpColors.textSecondary),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: CpSpace.md),
                    Semantics(header: true, child: Text(step.title, style: CpType.title1())),
                    const SizedBox(height: CpSpace.sm),
                    Text(step.summary, style: CpType.body(color: CpColors.textSecondary)),
                    const SizedBox(height: CpSpace.md),
                    Wrap(
                      spacing: CpSpace.lg,
                      runSpacing: CpSpace.xs,
                      children: [
                        _Meta(Icons.schedule, step.durationWeeks == 1 ? '1 semaine' : '${step.durationWeeks} semaines'),
                        if (step.labs.isNotEmpty)
                          _Meta(Icons.science_outlined, step.labs.length == 1 ? '1 lab' : '${step.labs.length} labs'),
                        const _Meta(Icons.menu_book_outlined, 'Lisible hors ligne', highlighted: true),
                      ],
                    ),
                    if (view.status == StepStatus.locked) ...[
                      const SizedBox(height: CpSpace.lg),
                      _LockedNotice(trackView: trackView, step: step),
                    ],
                    const SizedBox(height: CpSpace.xxl),
                    const SectionLabel('Compétences visées'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: CpSpace.sm,
                      runSpacing: CpSpace.sm,
                      children: [for (final s in step.skills) _SkillChip(s)],
                    ),
                    if (links.isNotEmpty) ...[
                      const SizedBox(height: CpSpace.xxl),
                      const SectionLabel('Ressources et labs'),
                      const SizedBox(height: 10),
                      GlassCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (var i = 0; i < links.length; i++) ...[
                              if (i > 0) const Divider(height: 1, color: CpColors.divider),
                              _LinkRow(link: links[i]),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (step.note != null) ...[
                      const SizedBox(height: CpSpace.lg),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, size: 18, color: CpColors.warning),
                          const SizedBox(width: CpSpace.sm),
                          Expanded(child: Text(step.note!, style: CpType.caption(color: CpColors.warning))),
                        ],
                      ),
                    ],
                    const SizedBox(height: CpSpace.xxl),
                    _ValidationCriterion(text: step.validation),
                  ],
                ),
              ),
            ),
            _ActionBar(
              view: view,
              onValidate: () async {
                final unlockedSteps = stepsUnlockedBy(track, step.id, validated, level);
                final before = trackView;
                await ref.read(progressProvider.notifier).validate(step.id);
                if (!context.mounted) return;
                final after = buildTrackView(track, ref.read(progressProvider), level);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    fullscreenDialog: true,
                    builder: (_) => StepValidatedScreen(
                      step: step,
                      trackTitle: track.title,
                      before: before,
                      after: after,
                      unlockedSteps: unlockedSteps,
                      specialtiesUnlocked: step.unlocks.isNotEmpty,
                    ),
                  ),
                );
              },
              onUnvalidate: () => ref.read(progressProvider.notifier).unvalidate(step.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text, {this.highlighted = false});

  final IconData icon;
  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? CpColors.primary : CpColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(text, style: CpType.caption(color: color)),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: CpColors.glass,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: CpColors.glassBorder),
      ),
      child: Text(label, style: cpText(13)),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.link});

  final LinkItem link;

  @override
  Widget build(BuildContext context) {
    final kind = link.isLab ? 'Lab' : _typeLabel(link.type);
    final meta = [kind, if (link.free) 'gratuit', link.lang.toUpperCase()].join(' · ');
    return Semantics(
      link: true,
      label: '${link.title}, $meta, ouvre le navigateur',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => openExternal(context, link.url),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: CpSpace.md),
          child: Row(
            children: [
              IconTile(icon: link.isLab ? Icons.science_outlined : _typeIcon(link.type)),
              const SizedBox(width: CpSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(link.title, style: cpText(15, weight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(meta, style: CpType.small()),
                  ],
                ),
              ),
              const SizedBox(width: CpSpace.sm),
              const Icon(Icons.open_in_new, size: 16, color: CpColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  static String _typeLabel(String? type) => switch (type) {
        'cours' => 'Cours',
        'video' => 'Vidéo',
        'doc' => 'Documentation',
        'livre' => 'Livre',
        'outil' => 'Outil',
        'carte' => 'Carte',
        'certification' => 'Certification',
        _ => 'Ressource',
      };

  static IconData _typeIcon(String? type) => switch (type) {
        'video' => Icons.play_circle_outline,
        'outil' => Icons.build_outlined,
        'carte' => Icons.alt_route,
        'certification' => Icons.workspace_premium_outlined,
        _ => Icons.menu_book_outlined,
      };
}

class _ValidationCriterion extends StatelessWidget {
  const _ValidationCriterion({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Padding(
        padding: const EdgeInsets.all(CpSpace.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.track_changes, size: 20, color: CpColors.primary),
            const SizedBox(width: CpSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pour valider l'étape", style: cpText(13, weight: FontWeight.w600)),
                  const SizedBox(height: CpSpace.xs),
                  Text(text, style: cpText(14, lineHeight: 20, color: CpColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(CpRadius.card));
    final path = Path()..addRRect(rect);
    final paint = Paint()
      ..color = CpColors.lockedRing
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LockedNotice extends StatelessWidget {
  const _LockedNotice({required this.trackView, required this.step});

  final TrackView trackView;
  final RoadmapStep step;

  @override
  Widget build(BuildContext context) {
    final missing = [
      for (final id in step.requires)
        if (!trackView.viewOf(id).isDone) trackView.viewOf(id).step.title,
    ];
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, size: 20, color: CpColors.textSecondary),
          const SizedBox(width: CpSpace.md),
          Expanded(
            child: Text(
              "Termine d'abord : ${missing.join(', ')}. Tu peux déjà lire la fiche pour te préparer.",
              style: CpType.caption(color: CpColors.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.view, required this.onValidate, required this.onUnvalidate});

  final StepView view;
  final Future<void> Function() onValidate;
  final VoidCallback onUnvalidate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduced = effectsReduced(context, ref);
    final Widget action = switch (view.status) {
      StepStatus.validated => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Validée le ${formatShortDate(view.validatedAt!)}',
              style: CpType.bodyStrong(color: CpColors.primary),
            ),
            QuietButton(label: 'Annuler la validation', onPressed: onUnvalidate),
          ],
        ),
      StepStatus.acquired => Padding(
          padding: const EdgeInsets.symmetric(vertical: CpSpace.md),
          child: Text(
            'Acquise avec ton niveau. Tu peux la réviser quand tu veux.',
            textAlign: TextAlign.center,
            style: CpType.caption(),
          ),
        ),
      StepStatus.locked => const GradientButton(
          label: 'Étape verrouillée',
          icon: Icons.lock_outline,
          onPressed: null,
        ),
      _ => GradientButton(
          label: 'Marquer comme validée',
          icon: Icons.check_rounded,
          onPressed: onValidate,
        ),
    };

    Widget bar = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(CpSpace.page, CpSpace.md, CpSpace.page, CpSpace.md),
      decoration: BoxDecoration(
        color: reduced ? CpColors.solidNav : const Color(0x8C0B0E12),
        border: const Border(top: BorderSide(color: CpColors.divider)),
      ),
      child: SafeArea(top: false, child: action),
    );
    if (!reduced) {
      bar = ClipRect(
        child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24), child: bar),
      );
    }
    return bar;
  }
}
