import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/glass.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import 'ethics_charter.dart';

/// Trois écrans : niveau, objectif, charte éthique. Aucun compte.
/// Avec [editing], l'écran sert à modifier le profil puis se ferme.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.editing = false});

  final bool editing;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  var _page = 0;
  Level? _level;
  String? _goal;
  var _goalAnswered = false;
  var _ethicsChecked = false;

  static const _goals = [
    ('defensive', 'Défensive (SOC)', 'Surveiller, détecter, réagir', CpTrackColors.defensive),
    ('offensive', 'Offensive', 'Tester les défenses, en toute légalité', CpTrackColors.offensive),
    ('forensic', 'Forensic', 'Enquêter après un incident', CpTrackColors.forensic),
    ('grc', 'GRC', 'Normes, risques et conformité', CpTrackColors.grc),
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _level = profile.level ?? (widget.editing ? null : Level.bts1);
    if (widget.editing) {
      _goal = profile.goal;
      _goalAnswered = true;
      _ethicsChecked = profile.ethicsAccepted;
    }
  }

  bool get _canContinue => switch (_page) {
        0 => _level != null,
        1 => _goalAnswered,
        _ => _ethicsChecked,
      };

  Future<void> _next() async {
    if (_page < 2) {
      setState(() => _page++);
      return;
    }
    await ref.read(profileProvider.notifier).save(level: _level!, goal: _goal);
    if (widget.editing && mounted) Navigator.of(context).pop();
  }

  void _back() {
    if (_page > 0) {
      setState(() => _page--);
    } else if (widget.editing) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = _page > 0 || widget.editing;
    return PopScope(
      canPop: _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: AmbientBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(CpSpace.page, CpSpace.md, CpSpace.page, CpSpace.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (canGoBack)
                        IconButton(
                          onPressed: _back,
                          tooltip: 'Retour',
                          icon: const Icon(Icons.chevron_left, color: CpColors.text),
                        )
                      else
                        const SizedBox(width: 48, height: 48),
                      const Spacer(),
                      Text('ÉTAPE ${_page + 1} SUR 3', style: CpType.label(color: CpColors.textSecondary)),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: CpSpace.sm),
                  _ProgressSegments(page: _page),
                  const SizedBox(height: 32),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: switch (_page) {
                        0 => _levelPage(),
                        1 => _goalPage(),
                        _ => _ethicsPage(),
                      },
                    ),
                  ),
                  GradientButton(
                    label: _page == 2 ? (widget.editing ? 'Enregistrer' : 'Commencer') : 'Continuer',
                    trailingIcon: Icons.arrow_forward,
                    onPressed: _canContinue ? _next : null,
                  ),
                  const SizedBox(height: CpSpace.md),
                  Text(
                    'Aucun compte. Tes réponses restent sur ton téléphone.',
                    textAlign: TextAlign.center,
                    style: CpType.small(color: CpColors.textTertiary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _levelPage() {
    return ListView(
      key: const ValueKey('level'),
      children: [
        const _Heading(
          title: 'Où en es-tu dans tes études ?',
          subtitle: 'On adapte ton point de départ. Tu pourras le changer plus tard.',
        ),
        const SizedBox(height: CpSpace.xxl),
        for (final level in Level.values) ...[
          _OptionTile(
            title: level.label,
            subtitle: level.hint,
            selected: _level == level,
            onTap: () => setState(() => _level = level),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _goalPage() {
    return ListView(
      key: const ValueKey('goal'),
      children: [
        const _Heading(
          title: 'Quel métier te tente ?',
          subtitle: "Ça oriente les conseils. Tu choisiras vraiment ta spécialité au bilan du tronc commun.",
        ),
        const SizedBox(height: CpSpace.xxl),
        for (final g in _goals) ...[
          _OptionTile(
            title: g.$2,
            subtitle: g.$3,
            dotColor: g.$4,
            selected: _goalAnswered && _goal == g.$1,
            onTap: () => setState(() {
              _goal = g.$1;
              _goalAnswered = true;
            }),
          ),
          const SizedBox(height: 10),
        ],
        _OptionTile(
          title: 'Je ne sais pas encore',
          subtitle: 'Le tronc commun est fait pour ça',
          selected: _goalAnswered && _goal == null,
          onTap: () => setState(() {
            _goal = null;
            _goalAnswered = true;
          }),
        ),
      ],
    );
  }

  Widget _ethicsPage() {
    return ListView(
      key: const ValueKey('ethics'),
      children: [
        const _Heading(
          title: 'Notre charte',
          subtitle: 'La cybersécurité donne du pouvoir. Voici les règles du jeu.',
        ),
        const SizedBox(height: CpSpace.xxl),
        const EthicsCharterCard(),
        const SizedBox(height: CpSpace.lg),
        Semantics(
          checked: _ethicsChecked,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(CpRadius.card),
              onTap: () => setState(() => _ethicsChecked = !_ethicsChecked),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: CpSpace.sm),
                child: Row(
                  children: [
                    Checkbox(
                      value: _ethicsChecked,
                      onChanged: (v) => setState(() => _ethicsChecked = v ?? false),
                      activeColor: CpColors.primary,
                      checkColor: CpColors.onPrimary,
                      side: const BorderSide(color: CpColors.textSecondary, width: 1.5),
                    ),
                    const SizedBox(width: CpSpace.xs),
                    Expanded(
                      child: Text(
                        "Je m'engage à pratiquer uniquement sur des environnements autorisés.",
                        style: CpType.body(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text(title, style: CpType.display())),
        const SizedBox(height: CpSpace.sm),
        Text(subtitle, style: CpType.body(color: CpColors.textSecondary)),
      ],
    );
  }
}

class _ProgressSegments extends StatelessWidget {
  const _ProgressSegments({required this.page});

  final int page;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: i <= page ? CpColors.primary : CpColors.track,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.dotColor,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(CpRadius.button);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(horizontal: CpSpace.lg, vertical: CpSpace.md),
            decoration: BoxDecoration(
              borderRadius: radius,
              color: selected ? CpColors.primary.withValues(alpha: 0.12) : CpColors.glass,
              border: Border.all(
                color: selected ? CpColors.primary.withValues(alpha: 0.65) : CpColors.glassBorder,
              ),
            ),
            child: Row(
              children: [
                if (dotColor != null) ...[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: CpSpace.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: cpText(16, weight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: CpType.caption()),
                    ],
                  ),
                ),
                const SizedBox(width: CpSpace.md),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? CpColors.primary : CpColors.lockedRing,
                      width: selected ? 2 : 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: selected
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: CpColors.primary),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
