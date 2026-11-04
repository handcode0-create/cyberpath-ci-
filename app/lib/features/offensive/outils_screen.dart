import 'package:flutter/material.dart';

import '../../core/links.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/glass.dart';
import '../../data/models.dart';

/// Catalogue des outils cités dans la piste Offensive : quand les utiliser,
/// quand ne pas les utiliser, et où les installer depuis une source
/// officielle (catalogue Kali ou dépôt d'origine, jamais une copie).
class OutilsScreen extends StatefulWidget {
  const OutilsScreen({super.key, required this.content, this.highlightToolId});

  final AppContent content;
  final String? highlightToolId;

  @override
  State<OutilsScreen> createState() => _OutilsScreenState();
}

class _OutilsScreenState extends State<OutilsScreen> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final catalog = widget.content.tools;
    final tools = _category == null ? catalog.tools : catalog.byCategory(_category!);

    return Scaffold(
      body: AmbientBackground(
        topColor: CpTrackColors.offensive,
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(CpSpace.page, CpSpace.lg, CpSpace.page, 0),
                sliver: SliverList.list(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Retour',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.chevron_left, color: CpColors.text),
                        ),
                        const Spacer(),
                        Text('OFFENSIVE · OUTILS', style: CpType.label(color: CpTrackColors.offensive)),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: CpSpace.md),
                    Semantics(header: true, child: Text('Boîte à outils', style: CpType.title1())),
                    const SizedBox(height: CpSpace.sm),
                    Text(catalog.intro, style: CpType.body(color: CpColors.textSecondary)),
                    const SizedBox(height: CpSpace.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 16, color: CpColors.warning),
                        const SizedBox(width: CpSpace.sm),
                        Expanded(child: Text(catalog.warning, style: CpType.caption(color: CpColors.warning))),
                      ],
                    ),
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
                      CpChip(label: 'Tous', selected: _category == null, onTap: () => setState(() => _category = null)),
                      for (final cat in catalog.categories) ...[
                        const SizedBox(width: CpSpace.sm),
                        CpChip(
                          label: cat.name,
                          selected: _category == cat.id,
                          onTap: () => setState(() => _category = cat.id),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(CpSpace.page, CpSpace.xl, CpSpace.page, CpSpace.navClearance),
                sliver: SliverList.list(
                  children: [
                    for (final tool in tools) ...[
                      _ToolCard(tool: tool, highlighted: tool.id == widget.highlightToolId),
                      const SizedBox(height: CpSpace.lg),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool, required this.highlighted});

  final SecTool tool;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      accent: highlighted ? CpColors.primary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tool.name, style: CpType.title2()),
          const SizedBox(height: CpSpace.xs),
          Text(tool.purpose, style: CpType.body(color: CpColors.textSecondary)),
          const SizedBox(height: CpSpace.md),
          _Row(icon: Icons.check_circle_outline, color: CpColors.primary, label: 'Utiliser', text: tool.useWhen),
          const SizedBox(height: CpSpace.sm),
          _Row(icon: Icons.cancel_outlined, color: CpColors.error, label: 'Éviter', text: tool.avoidWhen),
          const SizedBox(height: CpSpace.md),
          Wrap(
            spacing: CpSpace.sm,
            runSpacing: CpSpace.sm,
            children: [
              for (final src in tool.sources)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(99),
                    onTap: () => openExternal(context, src.url),
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
                          const Icon(Icons.open_in_new, size: 13, color: CpColors.textTertiary),
                          const SizedBox(width: 6),
                          Text(src.label, style: cpText(13, weight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.color, required this.label, required this.text});

  final IconData icon;
  final Color color;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: CpSpace.sm),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: cpText(13.5, lineHeight: 19, color: CpColors.text),
              children: [
                TextSpan(text: '$label : ', style: cpText(13.5, weight: FontWeight.w600, color: color)),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
