import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'glass.dart';

/// Bouton principal : dégradé Lagune et légère lueur.
class GradientButton extends ConsumerWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = onPressed != null;
    final reduced = effectsReduced(context, ref);
    final radius = BorderRadius.circular(CpRadius.button);
    final foreground = enabled ? CpColors.onPrimary : CpColors.textTertiary;

    return Semantics(
      button: true,
      enabled: enabled,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: enabled && !reduced
              ? [BoxShadow(color: CpColors.primary.withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 8))]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            height: height,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: enabled ? CpColors.primaryGradient : null,
              color: enabled ? null : CpColors.track,
            ),
            child: InkWell(
              borderRadius: radius,
              onTap: onPressed,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 19, color: foreground),
                    const SizedBox(width: CpSpace.sm),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: cpText(16, weight: FontWeight.w600, color: foreground),
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: CpSpace.sm),
                    Icon(trailingIcon, size: 19, color: foreground),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Action secondaire discrète, texte seul.
class QuietButton extends StatelessWidget {
  const QuietButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        foregroundColor: CpColors.textSecondary,
      ),
      child: Text(label, style: cpText(14, weight: FontWeight.w500, color: CpColors.textSecondary)),
    );
  }
}

/// Barre de progression lumineuse.
class GlowProgressBar extends ConsumerWidget {
  const GlowProgressBar({super.key, required this.value, required this.semanticLabel});

  final double value;
  final String semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduced = effectsReduced(context, ref);
    return Semantics(
      label: semanticLabel,
      value: '${(value * 100).round()} %',
      child: Container(
        height: 6,
        decoration: BoxDecoration(color: CpColors.track, borderRadius: BorderRadius.circular(99)),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: CpColors.progressGradient,
              boxShadow: reduced
                  ? null
                  : [BoxShadow(color: CpColors.primary.withValues(alpha: 0.6), blurRadius: 12)],
            ),
          ),
        ),
      ),
    );
  }
}

/// Puce de piste ou de compétence.
class CpChip extends StatelessWidget {
  const CpChip({
    super.key,
    required this.label,
    this.dotColor,
    this.selected = false,
    this.locked = false,
    this.onTap,
  });

  final String label;
  final Color? dotColor;
  final bool selected;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? CpColors.text : CpColors.textSecondary;
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: locked ? '$label, verrouillée' : label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(99),
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: selected ? CpColors.primary.withValues(alpha: 0.16) : CpColors.glass,
              border: Border.all(
                color: selected ? CpColors.primary.withValues(alpha: 0.7) : CpColors.glassBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dotColor != null) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(label, style: cpText(13, weight: selected ? FontWeight.w600 : FontWeight.w500, color: color)),
                if (locked) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.lock_outline, size: 13, color: color),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Petit titre de section.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: Text(text, style: cpText(13, weight: FontWeight.w600, color: CpColors.textSecondary)),
      );
}

/// Pastille d'information (« Disponible hors ligne », version…).
class InfoPill extends StatelessWidget {
  const InfoPill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CpColors.glass,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: CpColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: CpColors.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: cpText(12, color: CpColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Tuile d'icône carrée utilisée dans les listes.
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, this.highlighted = false, this.size = 36});

  final IconData icon;
  final bool highlighted;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CpRadius.tile),
        color: highlighted ? CpColors.primary.withValues(alpha: 0.14) : CpColors.glassRaised,
      ),
      child: Icon(icon, size: size / 2, color: highlighted ? CpColors.primary : CpColors.textSecondary),
    );
  }
}
