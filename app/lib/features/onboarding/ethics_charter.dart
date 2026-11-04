import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/glass.dart';

const ethicsRules = [
  (
    Icons.verified_user_outlined,
    'Seulement sur autorisation',
    "Tu t'entraînes sur ton labo ou sur les plateformes prévues pour ça. Jamais sur un système réel sans accord écrit.",
  ),
  (
    Icons.gavel_outlined,
    "La loi s'applique",
    "En Côte d'Ivoire, accéder sans autorisation à un système informatique est puni par la loi sur la cybercriminalité.",
  ),
  (
    Icons.handshake_outlined,
    'Tu protèges, tu ne nuis pas',
    'Une faille trouvée se signale à son propriétaire. Elle ne se revend pas et ne se publie pas sans son accord.',
  ),
];

class EthicsCharterCard extends StatelessWidget {
  const EthicsCharterCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          for (var i = 0; i < ethicsRules.length; i++) ...[
            if (i > 0) const Divider(height: CpSpace.xxl, color: CpColors.divider),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(ethicsRules[i].$1, size: 22, color: CpColors.primary),
                const SizedBox(width: CpSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ethicsRules[i].$2, style: CpType.bodyStrong()),
                      const SizedBox(height: 2),
                      Text(ethicsRules[i].$3, style: CpType.caption()),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
