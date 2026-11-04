import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/glass.dart';
import '../../data/models.dart';
import '../../domain/roadmap_logic.dart';
import '../../state/providers.dart';

/// Écran de succès après la validation d'une étape.
class StepValidatedScreen extends ConsumerStatefulWidget {
  const StepValidatedScreen({
    super.key,
    required this.step,
    required this.trackTitle,
    required this.before,
    required this.after,
    required this.unlockedSteps,
    required this.specialtiesUnlocked,
  });

  final RoadmapStep step;
  final String trackTitle;
  final TrackView before;
  final TrackView after;
  final List<RoadmapStep> unlockedSteps;
  final bool specialtiesUnlocked;

  @override
  ConsumerState<StepValidatedScreen> createState() => _StepValidatedScreenState();
}

class _StepValidatedScreenState extends ConsumerState<StepValidatedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(reduceEffectsProvider) || MediaQuery.of(context).disableAnimations) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _undo() async {
    await ref.read(progressProvider.notifier).unvalidate(widget.step.id);
    if (mounted) Navigator.of(context).pop();
  }

  void _continue() => Navigator.of(context).popUntil((route) => route.isFirst);

  @override
  Widget build(BuildContext context) {
    final reduced = effectsReduced(context, ref);
    final next = widget.specialtiesUnlocked
        ? 'Les 4 spécialités'
        : (widget.unlockedSteps.isEmpty ? null : widget.unlockedSteps.first.title);

    return Scaffold(
      body: AmbientBackground(
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(CpSpace.page, CpSpace.md, CpSpace.page, CpSpace.page),
              decoration: BoxDecoration(
                color: reduced ? CpColors.solidSurface : const Color(0x9E161B21),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(CpRadius.sheet)),
                border: const Border(top: BorderSide(color: Color(0x24FFFFFF))),
                boxShadow: reduced
                    ? null
                    : const [BoxShadow(color: Color(0x80000000), blurRadius: 60, offset: Offset(0, -20))],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: CpColors.lockedRing,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ScaleTransition(
                      scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: CpColors.primary.withValues(alpha: 0.14),
                          border: Border.all(color: CpColors.primary, width: 2),
                          boxShadow: reduced
                              ? null
                              : [BoxShadow(color: CpColors.primary.withValues(alpha: 0.45), blurRadius: 40)],
                        ),
                        child: const Icon(Icons.check_rounded, size: 36, color: CpColors.primary),
                      ),
                    ),
                    const SizedBox(height: CpSpace.xl),
                    Semantics(
                      header: true,
                      liveRegion: true,
                      child: Text('Étape validée', style: CpType.title1()),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.step.title} est dans ta poche.',
                      textAlign: TextAlign.center,
                      style: CpType.body(color: CpColors.textSecondary),
                    ),
                    const SizedBox(height: CpSpace.xl),
                    GlassCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${widget.trackTitle} · ${widget.after.done} sur ${widget.after.total}',
                                  style: CpType.caption(),
                                ),
                              ),
                              Text(
                                '${widget.before.percent} % → ${widget.after.percent} %',
                                style: CpType.numeric(15),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, _) => GlowProgressBar(
                              value: widget.before.ratio +
                                  (widget.after.ratio - widget.before.ratio) * _controller.value,
                              semanticLabel: 'Progression du ${widget.trackTitle}',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (next != null) ...[
                      const SizedBox(height: CpSpace.md),
                      GlassCard(
                        child: Row(
                          children: [
                            const IconTile(icon: Icons.lock_open_outlined),
                            const SizedBox(width: CpSpace.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.specialtiesUnlocked ? 'Débloquées' : 'Débloquée',
                                    style: CpType.small(),
                                  ),
                                  Text(next, style: CpType.bodyStrong()),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: CpSpace.xl),
                    GradientButton(
                      label: next == null ? 'Retour au parcours' : 'Voir la suite',
                      onPressed: _continue,
                    ),
                    const SizedBox(height: CpSpace.xs),
                    QuietButton(label: 'Annuler la validation', onPressed: _undo),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
