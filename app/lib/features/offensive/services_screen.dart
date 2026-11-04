import 'package:flutter/material.dart';

import '../../core/links.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/glass.dart';
import '../../data/models.dart';
import 'outils_screen.dart';

/// Liste des services qu'on rencontre après un scan. Chaque fiche dit quoi
/// vérifier en premier, quels outils utiliser et pourquoi, comment chercher
/// les CVE de la version trouvée, et vers quel lab légal s'entraîner.
class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key, required this.content});

  final AppContent content;

  @override
  Widget build(BuildContext context) {
    final catalog = content.services;
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
                  Text('OFFENSIVE · SERVICES', style: CpType.label(color: CpTrackColors.offensive)),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: CpSpace.md),
              Semantics(header: true, child: Text("J'ai trouvé ce service", style: CpType.title1())),
              const SizedBox(height: CpSpace.sm),
              Text(catalog.intro, style: CpType.body(color: CpColors.textSecondary)),
              const SizedBox(height: CpSpace.xl),
              for (final service in catalog.services) ...[
                _ServiceCard(service: service, content: content),
                const SizedBox(height: CpSpace.lg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.content});

  final DiscoveredService service;
  final AppContent content;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconTile(icon: Icons.dns_outlined, highlighted: true),
              const SizedBox(width: CpSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.name, style: CpType.title2()),
                    const SizedBox(height: 2),
                    Text('Port ${service.ports}', style: CpType.caption()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: CpSpace.sm),
          Text(service.whatItIs, style: CpType.body(color: CpColors.textSecondary)),
          const SizedBox(height: CpSpace.lg),
          const SectionLabel('À vérifier en premier'),
          const SizedBox(height: CpSpace.sm),
          for (final c in service.checkFirst) _BulletLine(c),
          const SizedBox(height: CpSpace.lg),
          const SectionLabel('Outils d\'énumération'),
          const SizedBox(height: CpSpace.sm),
          Wrap(
            spacing: CpSpace.sm,
            runSpacing: CpSpace.sm,
            children: [for (final ref in service.enumTools) _ToolRefChip(ref: ref, content: content)],
          ),
          const SizedBox(height: CpSpace.lg),
          const SectionLabel('Rechercher les CVE'),
          const SizedBox(height: CpSpace.sm),
          Text(service.cveLookup, style: CpType.body(color: CpColors.textSecondary)),
          const SizedBox(height: CpSpace.lg),
          const SectionLabel("S'entraîner légalement"),
          const SizedBox(height: CpSpace.sm),
          Column(
            children: [
              for (final lab in service.legalLabs) _LegalLabRow(lab: lab),
            ],
          ),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 7),
            child: Icon(Icons.circle, size: 5, color: CpColors.textTertiary),
          ),
          const SizedBox(width: CpSpace.sm),
          Expanded(child: Text(text, style: cpText(14, lineHeight: 20, color: CpColors.text))),
        ],
      ),
    );
  }
}

class _ToolRefChip extends StatelessWidget {
  const _ToolRefChip({required this.ref, required this.content});

  final ServiceToolRef ref;
  final AppContent content;

  @override
  Widget build(BuildContext context) {
    final tool = content.tools.byId(ref.toolId);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(CpRadius.tile),
        onTap: tool == null
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => OutilsScreen(content: content, highlightToolId: tool.id),
                  ),
                ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CpRadius.tile),
            color: CpColors.glass,
            border: Border.all(color: CpColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tool?.name ?? ref.toolId, style: cpText(13, weight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  const Icon(Icons.build_outlined, size: 13, color: CpColors.textTertiary),
                ],
              ),
              const SizedBox(height: 2),
              Text(ref.why, style: CpType.caption(color: CpColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalLabRow extends StatelessWidget {
  const _LegalLabRow({required this.lab});

  final LegalLab lab;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      label: '${lab.title}, ${lab.platform}, ouvre le navigateur',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => openExternal(context, lab.url),
        borderRadius: BorderRadius.circular(CpRadius.tile),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.science_outlined, size: 16, color: CpColors.textSecondary),
              const SizedBox(width: CpSpace.sm),
              Expanded(
                child: Text('${lab.title} · ${lab.platform}', style: cpText(14, weight: FontWeight.w500)),
              ),
              const Icon(Icons.open_in_new, size: 15, color: CpColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
