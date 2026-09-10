import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:musemend/app/theme/muse_colors.dart';

class MuseTopBar extends StatelessWidget {
  const MuseTopBar({this.trailing, super.key});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .42),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: .64)),
              ),
              child: const Icon(
                Icons.cloud_outlined,
                size: 21,
                color: MuseColors.teal,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback:
                      (bounds) => const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF4D858D), Color(0xFF9BC27C)],
                      ).createShader(bounds),
                  child: Text(
                    'MuseMend',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .1,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class MusePageTagline extends StatelessWidget {
  const MusePageTagline(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Text(
          '“$text”',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: MuseColors.ink.withValues(alpha: .78),
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class MusePageBadge extends StatelessWidget {
  const MusePageBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Trang $label',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 76, maxWidth: 110),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .44),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: Colors.white.withValues(alpha: .62)),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: MuseColors.teal,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MuseResponsiveList extends StatelessWidget {
  const MuseResponsiveList({
    required this.children,
    this.top = 20,
    this.bottom = 40,
    this.physics,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    super.key,
  });

  final List<Widget> children;
  final double top;
  final double bottom;
  final ScrollPhysics? physics;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  static double horizontalGutter(double viewportWidth) {
    final minimum =
        viewportWidth < 360
            ? 14.0
            : viewportWidth < 600
            ? 20.0
            : 24.0;
    final centered = (viewportWidth - 720) / 2;
    return centered > minimum ? centered : minimum;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = horizontalGutter(constraints.maxWidth);
        return ListView(
          physics: physics,
          keyboardDismissBehavior: keyboardDismissBehavior,
          padding: EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom),
          children: children,
        );
      },
    );
  }
}

class MuseContentFrame extends StatelessWidget {
  const MuseContentFrame({
    required this.child,
    this.maxWidth = 720,
    this.compactGutter = 16,
    this.regularGutter = 24,
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final double compactGutter;
  final double regularGutter;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter =
            constraints.maxWidth < 360 ? compactGutter : regularGutter;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
        );
      },
    );
  }
}

/// Shared visual language for page areas that are not covered by fixed artwork.
///
/// Feature widgets provide content and callbacks; these primitives own only
/// composition, colour, spacing and motion so a later local-first rewrite does
/// not have to touch presentation styling.
class MusePageBackground extends StatefulWidget {
  const MusePageBackground({required this.child, this.accent, super.key});

  final Widget child;
  final Color? accent;

  @override
  State<MusePageBackground> createState() => _MusePageBackgroundState();
}

class _MusePageBackgroundState extends State<MusePageBackground> {
  final ValueNotifier<double> _scrollOffset = ValueNotifier(0);

  @override
  void dispose() {
    _scrollOffset.dispose();
    super.dispose();
  }

  bool _handleScroll(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical) {
      _scrollOffset.value = notification.metrics.pixels.clamp(
        0,
        double.infinity,
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base =
        dark ? Theme.of(context).colorScheme.surface : MuseColors.cream;
    final tint = widget.accent ?? MuseColors.sky;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  dark
                      ? [base, Theme.of(context).colorScheme.surfaceContainer]
                      : [
                        MuseColors.sky.withValues(alpha: .82),
                        tint.withValues(alpha: .42),
                        base,
                        MuseColors.lavender.withValues(alpha: .4),
                      ],
              stops: dark ? null : const [0, .28, .66, 1],
            ),
          ),
        ),
        _MuseDriftingClouds(dark: dark, scrollOffset: _scrollOffset),
        NotificationListener<ScrollNotification>(
          onNotification: _handleScroll,
          child: widget.child,
        ),
      ],
    );
  }
}

class _MuseDriftingClouds extends StatefulWidget {
  const _MuseDriftingClouds({required this.dark, required this.scrollOffset});

  final bool dark;
  final ValueListenable<double> scrollOffset;

  @override
  State<_MuseDriftingClouds> createState() => _MuseDriftingCloudsState();
}

class _MuseDriftingCloudsState extends State<_MuseDriftingClouds>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _drift;
  var _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    _drift = CurvedAnimation(parent: _controller, curve: Curves.linear);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cloudColor = Colors.white.withValues(alpha: widget.dark ? .11 : .54);
    final shadowColor = MuseColors.sky.withValues(
      alpha: widget.dark ? .035 : .13,
    );
    return IgnorePointer(
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: _drift,
              builder: (context, child) {
                return ValueListenableBuilder<double>(
                  valueListenable: widget.scrollOffset,
                  builder: (context, scrollOffset, _) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;
                    if (!width.isFinite || !height.isFinite || height <= 0) {
                      return const SizedBox.shrink();
                    }
                    final horizontal =
                        _reduceMotion ? 0.0 : -width * _drift.value;
                    final vertical =
                        _reduceMotion ? 0.0 : -((scrollOffset * .14) % height);
                    return Transform.translate(
                      key: const ValueKey('muse-page-cloud-drift'),
                      offset: Offset(horizontal, vertical),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (var row = 0; row < 2; row++)
                            for (var column = 0; column < 2; column++)
                              Positioned(
                                left: column * width,
                                top: row * height,
                                width: width,
                                height: height,
                                child: CustomPaint(
                                  key: ValueKey(
                                    'muse-cloud-frame-$row-$column',
                                  ),
                                  painter: _CloudFramePainter(
                                    cloudColor: cloudColor,
                                    shadowColor: shadowColor,
                                  ),
                                ),
                              ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CloudFramePainter extends CustomPainter {
  const _CloudFramePainter({
    required this.cloudColor,
    required this.shadowColor,
  });

  final Color cloudColor;
  final Color shadowColor;

  @override
  void paint(Canvas canvas, Size size) {
    _drawCloud(canvas, Rect.fromLTWH(-58, size.height * .1, 248, 92));
    _drawCloud(
      canvas,
      Rect.fromLTWH(size.width - 228, size.height * .4, 304, 112),
    );
    _drawCloud(canvas, Rect.fromLTWH(18, size.height * .81, 196, 74));
  }

  void _drawCloud(Canvas canvas, Rect bounds) {
    final shadowPaint =
        Paint()
          ..color = shadowColor
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final cloudPaint =
        Paint()
          ..color = cloudColor
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.save();
    canvas.translate(0, bounds.height * .05);
    _drawCloudShape(canvas, bounds, shadowPaint);
    canvas.restore();
    _drawCloudShape(canvas, bounds, cloudPaint);
  }

  void _drawCloudShape(Canvas canvas, Rect bounds, Paint paint) {
    final width = bounds.width;
    final height = bounds.height;
    final left = bounds.left;
    final top = bounds.top;
    canvas.drawOval(
      Rect.fromLTWH(left, top + (height * .46), width, height * .5),
      paint,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        left + (width * .12),
        top + (height * .24),
        width * .36,
        height * .58,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromLTWH(left + (width * .36), top, width * .42, height * .82),
      paint,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        left + (width * .66),
        top + (height * .3),
        width * .25,
        height * .54,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CloudFramePainter oldDelegate) {
    return oldDelegate.cloudColor != cloudColor ||
        oldDelegate.shadowColor != shadowColor;
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
