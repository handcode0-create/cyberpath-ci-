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
import '../home_shell.dart';

class CertifsScreen extends ConsumerWidget {
  const CertifsScreen({super.key, required this.content});

  final AppContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(profileProvider.select((p) => p.goal));
    final catalog = content.certifications;
    final featured = catalog.items.where((c) => c.tracks.contains(Roadmap.coreTrackId)).firstOrNull;
    final others = catalog.items.where((c) => c != featured).toList()
      ..sort((a, b) {
        int rank(Certification c) => goal != null && c.tracks.contains(goal) ? 0 : 1;
        return rank(a).compareTo(rank(b));
      });
    final checkedDates = catalog.items.map((c) => c.checked).whereType<String>().toList()..sort();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(CpSpace.page, CpSpace.xl, CpSpace.page, CpSpace.navClearance),
        children: [
          const PageHeader(title: 'Certifications', subtitle: 'Quoi viser, quand, et combien ça coûte.'),
          const SizedBox(height: CpSpace.lg),
          if (featured != null) ...[
            _FeaturedCert(
              cert: featured,
              rate: catalog.usdToXof,
              afterStep: content.roadmap.step(featured.afterStep ?? ''),
            ),
            const SizedBox(height: CpSpace.xxl),
          ],
          const SectionLabel('Ensuite, selon ta spécialité'),
          const SizedBox(height: 10),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < others.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: CpColors.divider),
                  _CertRow(cert: others[i], rate: catalog.usdToXof),
                ],
              ],
            ),
          ),
          const SizedBox(height: CpSpace.lg),
          Text(
            'Prix officiels relevés le ${checkedDates.isEmpty ? '?' : _frenchDate(checkedDates.last)}, '
            'convertis à environ ${catalog.usdToXof} FCFA pour 1 USD. '
            "Reconfirme sur le site de l'organisme avant de payer.",
            style: CpType.small(color: CpColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _FeaturedCert extends StatelessWidget {
  const _FeaturedCert({required this.cert, required this.rate, required this.afterStep});

  final Certification cert;
  final int rate;
  final RoadmapStep? afterStep;

  @override
  Widget build(BuildContext context) {
    final price = cert.priceUsd;
    return GlassCard(
      accent: CpColors.primary,
      radius: CpRadius.cardLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TA PROCHAINE CIBLE', style: CpType.label()),
                    const SizedBox(height: CpSpace.xs),
                    Text(cert.title, style: cpText(19, weight: FontWeight.w700, lineHeight: 24)),
                    const SizedBox(height: 2),
                    Text('Niveau ${cert.levelLabel}', style: CpType.caption()),
                  ],
                ),
              ),
              const IconTile(icon: Icons.workspace_premium_outlined, highlighted: true, size: 44),
            ],
          ),
          const SizedBox(height: CpSpace.md),
          Row(
            children: [
              Expanded(
                child: _Fact(
                  label: 'Examen',
                  value: price == null ? 'Prix à vérifier' : '$price USD',
                  detail: price == null ? null : '≈ ${formatXof(roundToThousand(price * rate))} FCFA',
                  mono: price != null,
                ),
              ),
              const SizedBox(width: CpSpace.sm),
              Expanded(
                child: _Fact(
                  label: 'Quand',
                  value: 'Après le bilan',
                  detail: afterStep == null ? null : 'Tronc commun · ${afterStep!.code}',
                ),
              ),
            ],
          ),
          if (cert.notes.isNotEmpty) ...[
            const SizedBox(height: CpSpace.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: CpColors.warning),
                const SizedBox(width: CpSpace.sm),
                Expanded(child: Text(cert.notes, style: CpType.small(color: CpColors.warning))),
              ],
            ),
          ],
          const SizedBox(height: CpSpace.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => openExternal(context, cert.url),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Site officiel'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, this.detail, this.mono = false});

  final String label;
  final String value;
  final String? detail;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: CpSpace.md, vertical: 10),
      decoration: BoxDecoration(
        color: CpColors.glass,
        borderRadius: BorderRadius.circular(CpRadius.button - 2),
        border: Border.all(color: CpColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: cpText(11, color: CpColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: cpText(mono ? 15 : 14, weight: FontWeight.w600, mono: mono)),
          if (detail != null) Text(detail!, style: cpText(11, color: CpColors.textSecondary)),
        ],
      ),
    );
  }
}

class _CertRow extends StatelessWidget {
  const _CertRow({required this.cert, required this.rate});

  final Certification cert;
  final int rate;

  @override
  Widget build(BuildContext context) {
    final trackId = cert.tracks.isEmpty ? null : cert.tracks.first;
    final price = cert.priceUsd;
    return InkWell(
      onTap: () => openExternal(context, cert.url),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: CpSpace.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cert.title, style: cpText(15, weight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (trackId != null) ...[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(color: CpTrackColors.of(trackId), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          [if (trackId != null) _trackName(trackId), cert.levelLabel].join(' · '),
                          style: CpType.small(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: CpSpace.md),
            if (price != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$price USD', style: cpText(14, weight: FontWeight.w600, mono: true)),
                  Text('≈ ${formatXof(roundToThousand(price * rate))} FCFA', style: cpText(11, color: CpColors.textSecondary)),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: CpSpace.sm, vertical: CpSpace.xs),
                decoration: BoxDecoration(color: CpColors.glassRaised, borderRadius: BorderRadius.circular(8)),
                child: Text('Plus tard', style: cpText(11, color: CpColors.textSecondary)),
              ),
          ],
        ),
      ),
    );
  }

  static String _trackName(String id) => switch (id) {
        'defensive' => 'Défensive',
        'offensive' => 'Offensive',
        'forensic' => 'Forensic',
        'grc' => 'GRC',
        _ => 'Tronc commun',
      };
}

String _frenchDate(String iso) {
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  return '${formatShortDate(date)} ${date.year}';
}
