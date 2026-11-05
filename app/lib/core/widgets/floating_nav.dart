import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'glass.dart';

class NavItem {
  const NavItem({required this.label, required this.icon, required this.selectedIcon});

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Barre de navigation flottante en verre.
class FloatingNavBar extends ConsumerWidget {
  const FloatingNavBar({
    super.key,
    required this.items,
    required this.index,
    required this.onSelected,
  });

  final List<NavItem> items;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduced = effectsReduced(context, ref);
    final radius = BorderRadius.circular(CpRadius.nav);

    Widget bar = Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: radius,
        color: reduced ? CpColors.solidNav : const Color(0x8C12161C),
        border: Border.all(color: CpColors.glassBorder),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(child: _NavButton(item: items[i], selected: i == index, onTap: () => onSelected(i))),
        ],
      ),
    );

    if (!reduced) {
      bar = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24), child: bar),
      );
    }

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: reduced
              ? null
              : const [BoxShadow(color: Color(0x73000000), blurRadius: 40, offset: Offset(0, 16))],
        ),
        child: bar,
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.selected, required this.onTap});

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? CpColors.primary : CpColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: selected ? CpColors.primary.withValues(alpha: 0.14) : Colors.transparent,
              border: Border.all(
                color: selected ? CpColors.primary.withValues(alpha: 0.3) : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(selected ? item.selectedIcon : item.icon, size: 22, color: color),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: cpText(11, weight: selected ? FontWeight.w600 : FontWeight.w500, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
