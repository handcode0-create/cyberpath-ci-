import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/links.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/glass.dart';
import '../../data/content_repository.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../home_shell.dart';
import '../onboarding/ethics_charter.dart';
import '../onboarding/onboarding_screen.dart';

class PlusScreen extends ConsumerStatefulWidget {
  const PlusScreen({super.key, required this.content});

  final AppContent content;

  @override
  ConsumerState<PlusScreen> createState() => _PlusScreenState();
}

class _PlusScreenState extends ConsumerState<PlusScreen> {
  var _checking = false;

  Future<void> _checkUpdate() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _checking = true);
    final result = await ref
        .read(contentRepositoryProvider)
        .checkForUpdate(widget.content.roadmap.version);
    if (!mounted) return;
    setState(() => _checking = false);
    final message = switch (result.status) {
      UpdateStatus.updated => 'Roadmap mise à jour (v${result.version}). Ta progression est conservée.',
      UpdateStatus.upToDate => 'Ta roadmap est déjà à jour.',
      UpdateStatus.notConfigured => "Les mises à jour en ligne ne sont pas activées dans cette version de l'app.",
      UpdateStatus.failed => 'Mise à jour impossible. On garde la version actuelle. Réessaie avec du réseau.',
    };
    messenger.showSnackBar(SnackBar(content: Text(message)));
    if (result.status == UpdateStatus.updated) ref.invalidate(contentProvider);
  }

  void _showCharter() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF161B21),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(CpRadius.sheet)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(CpSpace.page, CpSpace.xl, CpSpace.page, CpSpace.page),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Charte éthique', style: CpType.title1()),
              const SizedBox(height: CpSpace.lg),
              const EthicsCharterCard(),
              const SizedBox(height: CpSpace.lg),
              GradientButton(label: 'Compris', onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final reduceEffects = ref.watch(reduceEffectsProvider);
    final roadmap = widget.content.roadmap;
    final canUpdate = ref.watch(contentRepositoryProvider).canUpdate;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(CpSpace.page, CpSpace.xl, CpSpace.page, CpSpace.navClearance),
        children: [
          const PageHeader(title: 'Plus'),
          const SizedBox(height: CpSpace.lg),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: CpSpace.lg, vertical: 14),
            child: Row(
              children: [
                const IconTile(icon: Icons.school_outlined, highlighted: true, size: 44),
                const SizedBox(width: CpSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.level?.label ?? 'Niveau à choisir', style: CpType.bodyStrong()),
                      Text('Objectif ${goalLabel(widget.content, profile.goal)}', style: CpType.caption()),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const OnboardingScreen(editing: true)),
                  ),
                  child: const Text('Modifier'),
                ),
              ],
            ),
          ),
          const SizedBox(height: CpSpace.xl),
          const SectionLabel('Réglages'),
          const SizedBox(height: CpSpace.sm),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const _ValueRow(label: 'Thème', value: 'Sombre'),
                const Divider(height: 1, color: CpColors.divider),
                MergeSemantics(
                  child: SwitchListTile(
                    value: reduceEffects,
                    onChanged: (v) => ref.read(reduceEffectsProvider.notifier).set(v),
                    contentPadding: const EdgeInsets.symmetric(horizontal: CpSpace.lg, vertical: 2),
                    title: Text('Réduire les effets', style: CpType.body()),
                    subtitle: Text(
                      'Moins de flou et de lueurs : plus fluide sur les petits téléphones',
                      style: CpType.small(),
                    ),
                  ),
                ),
                const Divider(height: 1, color: CpColors.divider),
                const _ValueRow(label: 'Langue', value: 'Français'),
              ],
            ),
          ),
          const SizedBox(height: CpSpace.xl),
          const SectionLabel('Contenu et communauté'),
          const SizedBox(height: CpSpace.sm),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: CpSpace.lg, vertical: CpSpace.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                text: 'Roadmap ',
                                style: CpType.body(),
                                children: [
                                  TextSpan(
                                    text: 'v${roadmap.version}',
                                    style: cpText(13, color: CpColors.textSecondary, mono: true),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.content.source == ContentSource.downloaded
                                  ? 'Mise à jour téléchargée · disponible hors ligne'
                                  : 'Incluse dans l\'app · disponible hors ligne',
                              style: CpType.small(color: CpColors.primary),
                            ),
                          ],
                        ),
                      ),
                      if (canUpdate)
                        OutlinedButton(
                          onPressed: _checking ? null : _checkUpdate,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: CpColors.text,
                            side: const BorderSide(color: CpColors.glassBorder),
                            shape: const StadiumBorder(),
                          ),
                          child: _checking
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: CpColors.primary),
                                )
                              : const Text('Vérifier'),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: CpColors.divider),
                _LinkTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Charte éthique',
                  subtitle: "Pratiquer seulement là où c'est autorisé",
                  onTap: _showCharter,
                ),
                if (repoUrl.isNotEmpty) ...[
                  const Divider(height: 1, color: CpColors.divider),
                  _LinkTile(
                    icon: Icons.code,
                    title: 'Contribuer sur GitHub',
                    subtitle: 'Ajoute une ressource, signale un lien mort',
                    external: true,
                    onTap: () => openExternal(context, repoUrl),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: CpSpace.xl),
          Text(
            'CyberPath CI 1.0 · open source\nCode MIT · contenu CC BY-SA 4.0 · par handCode Studio',
            textAlign: TextAlign.center,
            style: CpType.small(color: CpColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: CpSpace.lg),
        child: Row(
          children: [
            Expanded(child: Text(label, style: CpType.body())),
            Text(value, style: cpText(14, color: CpColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.external = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool external;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: CpSpace.lg, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: CpColors.textSecondary),
            const SizedBox(width: CpSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: CpType.body()),
                  Text(subtitle, style: CpType.small()),
                ],
              ),
            ),
            Icon(external ? Icons.open_in_new : Icons.chevron_right, size: 18, color: CpColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
