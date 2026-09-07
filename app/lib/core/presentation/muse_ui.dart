import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:musemend/app/theme/muse_colors.dart';

/// Shared visual language for the non-sky pages.
///
/// Feature widgets provide content and callbacks; these primitives own only
/// composition, colour, spacing and motion so a later local-first rewrite does
/// not have to touch presentation styling.
class MusePageBackground extends StatelessWidget {
  const MusePageBackground({required this.child, this.accent, super.key});

  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base =
        dark ? Theme.of(context).colorScheme.surface : MuseColors.cream;
    final tint = accent ?? MuseColors.sky;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              dark
                  ? [base, Theme.of(context).colorScheme.surfaceContainer]
                  : [
                    tint.withValues(alpha: .72),
                    base,
                    MuseColors.lavender.withValues(alpha: .44),
                  ],
          stops: dark ? null : const [0, .52, 1],
        ),
      ),
      child: child,
    );
  }
}

class MusePageHeader extends StatelessWidget {
  const MusePageHeader({
    required this.title,
    required this.subtitle,
    this.icon,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .66),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: .7)),
            ),
            child: Icon(icon, color: MuseColors.teal),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 5),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class MuseGlassCard extends StatelessWidget {
  const MuseGlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.tint,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final color = tint ?? Colors.white;
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: .68),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: .72)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 22,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class MuseSectionLabel extends StatelessWidget {
  const MuseSectionLabel(this.text, {this.trailing, super.key});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: MuseColors.teal,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class MusePill extends StatelessWidget {
  const MusePill({
    required this.label,
    this.icon,
    this.onTap,
    this.selected = false,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : MuseColors.teal;
    final background =
        selected ? MuseColors.teal : Colors.white.withValues(alpha: .68);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color:
                  selected
                      ? MuseColors.teal
                      : Colors.white.withValues(alpha: .8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
