import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/tokens.dart';
import '../core/theme/typography.dart';
import '../core/widgets/controls.dart';
import '../core/widgets/floating_nav.dart';
import '../core/widgets/glass.dart';
import '../data/models.dart';
import '../state/providers.dart';
import 'certifs/certifs_screen.dart';
import 'metiers/metiers_screen.dart';
import 'parcours/parcours_screen.dart';
import 'plus/plus_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  var _index = 0;

  static const _items = [
    NavItem(label: 'Parcours', icon: Icons.map_outlined, selectedIcon: Icons.map),
    NavItem(label: 'Métiers', icon: Icons.work_outline, selectedIcon: Icons.work),
    NavItem(label: 'Certifs', icon: Icons.workspace_premium_outlined, selectedIcon: Icons.workspace_premium),
    NavItem(label: 'Plus', icon: Icons.more_horiz, selectedIcon: Icons.more_horiz),
  ];

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(contentProvider);
    return Scaffold(
      body: AmbientBackground(
        child: content.when(
          loading: () => const Center(child: CircularProgressIndicator(color: CpColors.primary)),
          error: (error, _) => _ContentError(onRetry: () => ref.invalidate(contentProvider)),
          data: (data) => Stack(
            children: [
              Positioned.fill(
                child: IndexedStack(
                  index: _index,
                  children: [
                    ParcoursScreen(content: data),
                    MetiersScreen(content: data),
                    CertifsScreen(content: data),
                    PlusScreen(content: data),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: FloatingNavBar(
                  items: _items,
                  index: _index,
                  onSelected: (i) => setState(() => _index = i),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentError extends StatelessWidget {
  const _ContentError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(CpSpace.page),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: CpColors.errorText, size: 36),
            const SizedBox(height: CpSpace.lg),
            Text('Impossible de lire la roadmap', style: CpType.title2(), textAlign: TextAlign.center),
            const SizedBox(height: CpSpace.sm),
            Text(
              "Le contenu de l'app semble abîmé. Réessaie ; si le problème continue, réinstalle l'app.",
              style: CpType.body(color: CpColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: CpSpace.xxl),
            GradientButton(label: 'Réessayer', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

/// Titre de page commun aux onglets.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(header: true, child: Text(title, style: CpType.display())),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: CpSpace.xs),
          Text(subtitle!, style: cpText(14, lineHeight: 20, color: CpColors.textSecondary)),
        ],
      ],
    );
  }
}

/// Libellé court d'une spécialité visée.
String goalLabel(AppContent content, String? goal) =>
    content.careers.byId(goal)?.title ?? 'Spécialité à choisir';
