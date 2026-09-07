import 'package:flutter/material.dart';

/// The fixed sky artwork used by the Reflect screen.
///
/// The bundled image is the original 1024×1536 export used by Figma's
/// 390×560 image layer. The painter remains a deterministic fallback when an
/// asset bundle is damaged; it is not part of the normal composition.
class SkyScene extends StatelessWidget {
  const SkyScene({super.key, this.height = 510});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: Image.asset(
          'assets/illustrations/journey/sky-background.png',
          cacheWidth: 1024,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder:
              (context, error, stackTrace) =>
                  CustomPaint(painter: _SkyScenePainter()),
        ),
      ),
    );
  }
}

class CloudMascot extends StatefulWidget {
  const CloudMascot({super.key, this.mood});

  final String? mood;

  @override
  State<CloudMascot> createState() => _CloudMascotState();
}

class _CloudMascotState extends State<CloudMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _float = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          widget.mood == null
              ? 'Linh vật mây của MuseMend'
              : 'Mây đang đồng hành',
      image: true,
      child: AnimatedBuilder(
        animation: _float,
        builder: (context, child) {
          return Transform.translate(
            // Keep the motion deliberately small so it feels like breathing,
            // not a moving layout element over the check-in card.
            offset: Offset(0, -3 * _float.value),
            child: child,
          );
        },
        child: Image.asset(
          'assets/illustrations/clouds/mascot-cloud.png',
          cacheWidth: 512,
          width: 145,
          height: 97,
          fit: BoxFit.contain,
          errorBuilder:
              (context, error, stackTrace) => const SizedBox(
                width: 145,
                height: 97,
                child: Icon(Icons.cloud, size: 72),
              ),
        ),
      ),
    );
  }
}

class _SkyScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final sky =
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDFF3FA), Color(0xFFF8F7F1)],
          ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final sun = Paint()..color = const Color(0xFFFFE7A8).withValues(alpha: .62);
    canvas.drawCircle(Offset(width * .79, 95), 42, sun);

    _drawCloud(canvas, Offset(width * .18, 102), 1.0);
    _drawCloud(canvas, Offset(width * .82, 178), .72);
    _drawHill(canvas, size, 0.62, const Color(0xFFC7E5D4), .08);
    _drawHill(canvas, size, 0.72, const Color(0xFFAED4C2), .16);
    _drawRiver(canvas, size);
    _drawHouse(canvas, Offset(width * .18, size.height * .70), width * .15);
    _drawSwing(canvas, Offset(width * .72, size.height * .67), width * .12);
  }

  void _drawCloud(Canvas canvas, Offset center, double scale) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .74);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-10 * scale, 5 * scale),
        width: 68 * scale,
        height: 25 * scale,
      ),
      paint,
    );
    canvas.drawCircle(center.translate(-25 * scale, 0), 18 * scale, paint);
    canvas.drawCircle(center.translate(0, -9 * scale), 26 * scale, paint);
    canvas.drawCircle(center.translate(25 * scale, 1), 17 * scale, paint);
  }

  void _drawHill(
    Canvas canvas,
    Size size,
    double topFactor,
    Color color,
    double sway,
  ) {
    final path = Path()..moveTo(0, size.height * topFactor);
    path.cubicTo(
      size.width * .22,
      size.height * (topFactor - .10),
      size.width * .35,
      size.height * (topFactor + sway),
      size.width * .57,
      size.height * (topFactor - .08),
    );
    path.cubicTo(
      size.width * .74,
      size.height * (topFactor - .15),
      size.width * .86,
      size.height * (topFactor + .08),
      size.width,
      size.height * (topFactor - .03),
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawRiver(Canvas canvas, Size size) {
    final path = Path()..moveTo(size.width * .44, size.height);
    path.cubicTo(
      size.width * .57,
      size.height * .91,
      size.width * .50,
      size.height * .85,
      size.width * .61,
      size.height * .76,
    );
    path.cubicTo(
      size.width * .72,
      size.height * .68,
      size.width * .61,
      size.height * .64,
      size.width * .68,
      size.height * .56,
    );
    path.lineTo(size.width * .82, size.height * .56);
    path.cubicTo(
      size.width * .73,
      size.height * .67,
      size.width * .87,
      size.height * .76,
      size.width * .70,
      size.height * .89,
    );
    path.cubicTo(
      size.width * .63,
      size.height * .96,
      size.width * .67,
      size.height,
      size.width * .67,
      size.height,
    );
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFB8E4ED));
  }

  void _drawHouse(Canvas canvas, Offset origin, double width) {
    final wall = Paint()..color = const Color(0xFFFFE4C8);
    final roof = Paint()..color = const Color(0xFFD88B77);
    canvas.drawRect(
      Rect.fromLTWH(origin.dx, origin.dy, width, width * .66),
      wall,
    );
    final roofPath =
        Path()
          ..moveTo(origin.dx - width * .12, origin.dy)
          ..lineTo(origin.dx + width * .5, origin.dy - width * .42)
          ..lineTo(origin.dx + width * 1.12, origin.dy)
          ..close();
    canvas.drawPath(roofPath, roof);
    canvas.drawRect(
      Rect.fromLTWH(
        origin.dx + width * .42,
        origin.dy + width * .32,
        width * .19,
        width * .34,
      ),
      Paint()..color = const Color(0xFF8FBBC2),
    );
  }

  void _drawSwing(Canvas canvas, Offset origin, double width) {
    final paint =
        Paint()
          ..color = const Color(0xFF7CA697)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;
    canvas.drawLine(
      origin.translate(-width, 0),
      origin.translate(0, -width),
      paint,
    );
    canvas.drawLine(
      origin.translate(0, -width),
      origin.translate(width, 0),
      paint,
    );
    canvas.drawLine(
      origin.translate(-width * .6, -width * .35),
      origin.translate(-width * .6, width * .34),
      paint,
    );
    canvas.drawLine(
      origin.translate(width * .6, -width * .35),
      origin.translate(width * .6, width * .34),
      paint,
    );
    canvas.drawLine(
      origin.translate(-width * .72, width * .34),
      origin.translate(width * .72, width * .34),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
