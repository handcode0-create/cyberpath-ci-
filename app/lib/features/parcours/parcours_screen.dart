import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/links.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/step_node.dart';
import '../../data/models.dart';
import '../../domain/roadmap_logic.dart';
import '../../state/providers.dart';
import '../home_shell.dart';
import '../offensive/methode_screen.dart';
import '../offensive/outils_screen.dart';
import '../offensive/services_screen.dart';
import 'step_detail_screen.dart';

class ParcoursScreen extends ConsumerStatefulWidget {
  const ParcoursScreen({super.key, required this.content});

  final AppContent content;

  @override
  ConsumerState<ParcoursScreen> createState() => _ParcoursScreenState();
}

class _ParcoursScreenState extends ConsumerState<ParcoursScreen> {
  String _trackId = Roadmap.coreTrackId;
  var _showEarlier = false;

  @override
  Widget build(BuildContext context) {
    final roadmap = widget.content.roadmap;
    final validated = ref.watch(progressProvider);
    final profile = ref.watch(profileProvider);
    final unlocked = unlockedSpecialties(roadmap, validated);
    final coreView = buildTrackView(roadmap.core, validated, profile.level);

    final specialties = [...widget.content.careers.specialties]
      ..sort((a, b) => (a.id == profile.goal ? 0 : 1).compareTo(b.id == profile.goal ? 0 : 1));

    final selectedTrack = roadmap.track(_trackId);
    final isCore = _trackId == Roadmap.coreTrackId;
    final view = selectedTrack == null || (!isCore && !unlocked.contains(_trackId))
        ? null
        : buildTrackView(selectedTrack, validated, isCore ? profile.level : null);

    final subtitle = [
      if (profile.level != null) profile.level!.label,
      'objectif ${goalLabel(widget.content, profile.goal)}',
    ].join(' · ');

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(CpSpace.page, CpSpace.lg, CpSpace.page, 0),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    Text('CYBERPATH CI', style: CpType.label()),
                    const Spacer(),
                    const InfoPill(icon: Icons.offline_pin_outlined, label: 'Disponible hors ligne'),
                  ],
                ),
                const SizedBox(height: CpSpace.lg),
                PageHeader(title: 'Ton parcours', subtitle: subtitle),
                const SizedBox(height: CpSpace.lg),
                _ProgressCard(view: coreView),
                const SizedBox(height: CpSpace.lg),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: CpSpace.page),
                children: [
                  CpChip(
                    label: 'Tronc commun',
                    selected: isCore,
                    onTap: () => setState(() => _trackId = Roadmap.coreTrackId),
                  ),
                  for (final s in specialties) ...[
                    const SizedBox(width: CpSpace.sm),
                    CpChip(
                      label: s.title,
                      dotColor: CpTrackColors.of(s.id),
                      selected: _trackId == s.id,
                      locked: !unlocked.contains(s.id),
                      onTap: () => setState(() => _trackId = s.id),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (view != null && _trackId == 'offensive')
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(CpSpace.page, CpSpace.xl, CpSpace.page, 0),
              sliver: SliverToBoxAdapter(child: _OffensiveTools(content: widget.content)),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(CpSpace.page, CpSpace.xl, CpSpace.page, CpSpace.navClearance),
            sliver: view == null
                ? SliverToBoxAdapter(
                    child: _SpecialtyPlaceholder(
                      specialty: widget.content.careers.byId(_trackId),
                      unlocked: unlocked.contains(_trackId),
                    ),
                  )
                : _timeline(view),
          ),
        ],
      ),
    );
  }

  Widget _timeline(TrackView view) {
    final current = view.current;
    final firstOpen = current?.index ?? view.steps.length;
    final earlierDone = view.steps.where((s) => s.index < firstOpen && s.isDone).length;
    final hidden = _showEarlier || earlierDone <= 2 ? 0 : earlierDone - 2;
    final visible = view.steps.skip(hidden).toList();

    return SliverList.list(
      children: [
        if (hidden > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _showEarlier = true),
              style: TextButton.styleFrom(
                foregroundColor: CpColors.textSecondary,
                padding: const EdgeInsets.only(left: 40, right: 8),
              ),
              child: Text(
                hidden == 1 ? "Voir l'étape précédente" : 'Voir les $hidden premières étapes',
                style: CpType.caption(),
              ),
            ),
          ),
        for (var i = 0; i < visible.length; i++)
          _TimelineRow(
            view: visible[i],
            isLast: i == visible.length - 1,
            onOpen: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => StepDetailScreen(
                  content: widget.content,
                  trackId: view.track.id,
                  stepId: visible[i].step.id,
                ),
              ),
            ),
          ),
        if (view.completed) ...[
          const SizedBox(height: CpSpace.lg),
          GlassCard(
            accent: CpColors.primary,
            child: Text(
              view.track.id == Roadmap.coreTrackId
                  ? 'Tronc commun terminé. Tes spécialités sont ouvertes : choisis ta piste dans les puces ci-dessus.'
                  : 'Piste terminée. Bravo !',
              style: CpType.body(),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.view});

  final TrackView view;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(view.track.title, style: CpType.caption()),
                    const SizedBox(height: 2),
                    Text('${view.done} étapes sur ${view.total} acquises', style: CpType.bodyStrong()),
                  ],
                ),
              ),
              Text('${view.percent} %', style: CpType.numeric(24)),
            ],
          ),
          const SizedBox(height: CpSpace.md),
          GlowProgressBar(value: view.ratio, semanticLabel: 'Progression du ${view.track.title}'),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.view, required this.isLast, required this.onOpen});

  final StepView view;
  final bool isLast;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final connectorColor = view.isDone ? CpColors.primary : CpColors.glassBorder;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                StepNode(status: view.status),
                if (!isLast) Expanded(child: Container(width: 2, color: connectorColor)),
              ],
            ),
          ),
          const SizedBox(width: CpSpace.lg),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: view.status == StepStatus.current
                  ? _CurrentStepCard(view: view, onOpen: onOpen)
                  : _CompactStep(view: view, onOpen: onOpen),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactStep extends StatelessWidget {
  const _CompactStep({required this.view, required this.onOpen});

  final StepView view;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final step = view.step;
    final detail = switch (view.status) {
      StepStatus.validated => 'Validée le ${formatShortDate(view.validatedAt!)}',
      StepStatus.acquired => 'Acquise avec ton niveau',
      StepStatus.available => 'Ouverte · ${_weeks(step.durationWeeks)}',
      StepStatus.locked => 'Verrouillée · ${_weeks(step.durationWeeks)}',
      StepStatus.current => '',
    };
    final muted = view.isDone;
    return Semantics(
      button: true,
      label: '${step.code} ${step.title}, ${statusLabel(view.status)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(CpRadius.tile),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: cpText(15, weight: FontWeight.w500, color: muted ? CpColors.textSecondary : CpColors.text),
              ),
              const SizedBox(height: 2),
              Text(detail, style: CpType.caption(color: CpColors.textTertiary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentStepCard extends StatelessWidget {
  const _CurrentStepCard({required this.view, required this.onOpen});

  final StepView view;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final step = view.step;
    return GlassCard(
      accent: CpColors.primary,
      radius: CpRadius.cardLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${step.code} · EN COURS', style: CpType.label()),
          const SizedBox(height: CpSpace.xs),
          Text(step.title, style: CpType.title2()),
          const SizedBox(height: CpSpace.md),
          Wrap(
            spacing: CpSpace.lg,
            runSpacing: CpSpace.xs,
            children: [
              _Meta(icon: Icons.schedule, text: _weeks(step.durationWeeks)),
              if (step.labs.isNotEmpty)
                _Meta(
                  icon: Icons.science_outlined,
                  text: step.labs.length == 1 ? '1 lab' : '${step.labs.length} labs',
                ),
            ],
          ),
          const SizedBox(height: CpSpace.md),
          GradientButton(
            label: "Continuer l'étape",
            trailingIcon: Icons.arrow_forward,
            height: 44,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: CpColors.textSecondary),
        const SizedBox(width: 6),
        Text(text, style: CpType.caption()),
      ],
    );
  }
}

class _SpecialtyPlaceholder extends StatelessWidget {
  const _SpecialtyPlaceholder({required this.specialty, required this.unlocked});

  final Specialty? specialty;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final title = specialty?.title ?? 'Cette spécialité';
    return GlassCard(
      padding: const EdgeInsets.all(CpSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            unlocked ? Icons.construction_outlined : Icons.lock_outline,
            color: CpColors.textSecondary,
          ),
          const SizedBox(height: CpSpace.md),
          Text(
            unlocked ? '$title : contenu en préparation' : '$title se débloque au bilan',
            style: CpType.title2(),
          ),
          const SizedBox(height: CpSpace.sm),
          Text(
            unlocked
                ? "Les étapes de cette piste arrivent bientôt. Tu peux aider à les écrire : chaque contribution sur GitHub profite à tous les étudiants."
                : "Valide l'étape « Bilan : choisir ta spécialité » du tronc commun pour ouvrir les 4 spécialités.",
            style: CpType.body(color: CpColors.textSecondary),
          ),
          if (unlocked && repoUrl.isNotEmpty) ...[
            const SizedBox(height: CpSpace.lg),
            TextButton.icon(
              onPressed: () => openExternal(context, repoUrl),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Contribuer sur GitHub'),
            ),
          ],
        ],
      ),
    );
  }
}

String _weeks(int n) => n == 1 ? '1 semaine' : '$n semaines';

class _OffensiveTools extends StatelessWidget {
  const _OffensiveTools({required this.content});

  final AppContent content;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(CpSpace.md),
      child: Row(
        children: [
          Expanded(
            child: _Tile(
              icon: Icons.route_outlined,
              label: 'Méthode',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => MethodeScreen(content: content)),
              ),
            ),
          ),
          const SizedBox(width: CpSpace.sm),
          Expanded(
            child: _Tile(
              icon: Icons.dns_outlined,
              label: 'Services',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => ServicesScreen(content: content)),
              ),
            ),
          ),
          const SizedBox(width: CpSpace.sm),
          Expanded(
            child: _Tile(
              icon: Icons.build_outlined,
              label: 'Outils',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => OutilsScreen(content: content)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(CpRadius.tile),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: CpSpace.sm),
            child: Column(
              children: [
                Icon(icon, size: 20, color: CpTrackColors.offensive),
                const SizedBox(height: 6),
                Text(label, style: cpText(12.5, weight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
