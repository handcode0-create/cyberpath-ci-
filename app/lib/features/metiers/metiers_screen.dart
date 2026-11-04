import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/glass.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../home_shell.dart';

class MetiersScreen extends ConsumerStatefulWidget {
  const MetiersScreen({super.key, required this.content});

  final AppContent content;

  @override
  ConsumerState<MetiersScreen> createState() => _MetiersScreenState();
}

class _MetiersScreenState extends ConsumerState<MetiersScreen> {
  String? _expanded;

  @override
  Widget build(BuildContext context) {
    final goal = ref.watch(profileProvider.select((p) => p.goal));
    final careers = widget.content.careers;
    final featured = careers.byId(goal);
    final others = careers.specialties.where((s) => s.id != featured?.id).toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(CpSpace.page, CpSpace.xl, CpSpace.page, CpSpace.navClearance),
        children: [
          const PageHeader(title: 'Métiers', subtitle: "Où mène chaque spécialité, en Côte d'Ivoire."),
          const SizedBox(height: CpSpace.lg),
          if (featured != null) ...[
            _SpecialtyDetails(
              specialty: featured,
              certification: widget.content.certifications.byId(featured.certification),
              isGoal: true,
            ),
            const SizedBox(height: CpSpace.lg),
          ],
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < others.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: CpColors.divider),
                  _SpecialtyRow(
                    specialty: others[i],
                    certification: widget.content.certifications.byId(others[i].certification),
                    expanded: _expanded == others[i].id,
                    onTap: () => setState(
                      () => _expanded = _expanded == others[i].id ? null : others[i].id,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: CpSpace.xxl),
          const SectionLabel('Les acteurs à connaître'),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < careers.actors.length; i++) ...[
                if (i > 0) const SizedBox(width: CpSpace.sm),
                Expanded(child: _ActorCard(actor: careers.actors[i])),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SpecialtyDetails extends StatelessWidget {
  const _SpecialtyDetails({required this.specialty, required this.certification, required this.isGoal});

  final Specialty specialty;
  final Certification? certification;
  final bool isGoal;

  @override
  Widget build(BuildContext context) {
    final color = CpTrackColors.of(specialty.id);
    return GlassCard(
      accent: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: CpSpace.sm),
              Expanded(child: Text(specialty.title, style: CpType.title2())),
              if (isGoal)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('Ton objectif', style: cpText(12, weight: FontWeight.w600, color: color)),
                ),
            ],
          ),
          const SizedBox(height: CpSpace.md),
          _Fact(label: 'Postes visés', value: specialty.roles),
          const SizedBox(height: 10),
          _Fact(label: 'Qui recrute', value: specialty.recruiters),
          if (certification != null) ...[
            const SizedBox(height: 10),
            _Fact(label: 'Certification à viser', value: '${certification!.title}, après le tronc commun'),
          ],
        ],
      ),
    );
  }
}

class _SpecialtyRow extends StatelessWidget {
  const _SpecialtyRow({
    required this.specialty,
    required this.certification,
    required this.expanded,
    required this.onTap,
  });

  final Specialty specialty;
  final Certification? certification;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = CpTrackColors.of(specialty.id);
    return Semantics(
      button: true,
      hint: expanded ? 'Replier' : 'Déplier',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: CpSpace.lg, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: CpSpace.sm),
                            Text(specialty.title, style: cpText(15, weight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(specialty.roles, style: CpType.caption()),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.expand_more, color: CpColors.textTertiary),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: expanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: CpSpace.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Fact(label: 'Qui recrute', value: specialty.recruiters),
                            if (certification != null) ...[
                              const SizedBox(height: 10),
                              _Fact(label: 'Certification à viser', value: certification!.title),
                            ],
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: CpType.small()),
        const SizedBox(height: 2),
        Text(value, style: cpText(14, lineHeight: 20)),
      ],
    );
  }
}

class _ActorCard extends StatelessWidget {
  const _ActorCard({required this.actor});

  final Actor actor;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(CpSpace.md),
      radius: CpRadius.button,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(actor.name, style: cpText(14, weight: FontWeight.w600, mono: true)),
          const SizedBox(height: CpSpace.xs),
          Text(actor.description, style: cpText(12, lineHeight: 16, color: CpColors.textSecondary)),
        ],
      ),
    );
  }
}
