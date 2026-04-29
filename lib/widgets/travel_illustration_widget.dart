import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

enum TravelScene { explore, book, enjoy, loginScene, registerScene }

class TravelIllustrationWidget extends StatefulWidget {
  final TravelScene scene;
  final double height;
  const TravelIllustrationWidget({
    super.key,
    required this.scene,
    required this.height,
  });
  @override
  State<TravelIllustrationWidget> createState() =>
      _TravelIllustrationWidgetState();
}

class _TravelIllustrationWidgetState extends State<TravelIllustrationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.linear);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _anim,
        builder:
            (_, __) => CustomPaint(
              painter: _TravelPainter(
                scene: widget.scene,
                progress: _anim.value,
                isDark: isDark,
              ),
              size: Size.infinite,
            ),
      ),
    );
  }
}

class _TravelPainter extends CustomPainter {
  final TravelScene scene;
  final double progress;
  final bool isDark;
  _TravelPainter({
    required this.scene,
    required this.progress,
    required this.isDark,
  });

  @override
  bool shouldRepaint(_TravelPainter old) =>
      old.progress != progress || old.isDark != isDark;

  @override
  void paint(Canvas canvas, Size size) {
    _drawSky(canvas, size);
    _drawStars(canvas, size);
    _drawClouds(canvas, size);
    switch (scene) {
      case TravelScene.explore:
        _drawGlobe(
          canvas,
          size,
          cx: size.width * 0.5,
          cy: size.height * 0.62,
          r: size.width * 0.32,
        );
        _drawEiffelTower(canvas, size);
        _drawHotAirBalloon(canvas, size, size.width * 0.15, size.height * 0.12);
        _drawAirplane(canvas, size, size.width * 0.72, size.height * 0.10);
        break;
      case TravelScene.book:
        canvas.save();
        canvas.scale(0.6, 0.6);
        canvas.saveLayer(
          null,
          Paint()
            ..color = Colors.white.withAlpha((0.4 * 255).round())
            ..blendMode = BlendMode.srcOver,
        );
        _drawDestinationSigns(
          canvas,
          size,
          size.width * 0.05,
          size.height * 0.35,
        );
        canvas.restore();
        canvas.restore();

        canvas.drawLine(
          Offset(0, size.height * 0.78),
          Offset(size.width, size.height * 0.78),
          Paint()
            ..color = Colors.white.withAlpha((0.10 * 255).round())
            ..strokeWidth = 1,
        );

        canvas.save();
        canvas.translate(0, size.height * 0.78 * 2);
        canvas.scale(1, -0.3);
        canvas.saveLayer(
          null,
          Paint()..color = Colors.white.withAlpha((0.08 * 255).round()),
        );
        _drawSuitcase(
          canvas,
          size,
          size.width * 0.225,
          size.height * 0.22,
          size.width * 0.55,
        );
        canvas.restore();
        canvas.restore();

        _drawSuitcase(
          canvas,
          size,
          size.width * 0.225,
          size.height * 0.22,
          size.width * 0.55,
        );
        _drawAirplane(canvas, size, size.width * 0.78, size.height * 0.08);
        _drawPalmTree(canvas, size, size.width * 0.78, size.height * 0.50);
        break;
      case TravelScene.enjoy:
        _drawGlobe(
          canvas,
          size,
          cx: size.width * 0.5,
          cy: size.height * 0.60,
          r: size.width * 0.28,
        );
        _drawHotAirBalloon(canvas, size, size.width * 0.75, size.height * 0.08);
        _drawPassport(canvas, size, size.width * 0.18, size.height * 0.55);
        _drawCamera(canvas, size, size.width * 0.68, size.height * 0.60);
        break;
      case TravelScene.loginScene:
        _drawGlobe(
          canvas,
          size,
          cx: size.width * 0.62,
          cy: size.height * 0.58,
          r: size.width * 0.30,
        );
        _drawSignpost(canvas, size, size.width * 0.08, size.height * 0.20);
        _drawSuitcase(
          canvas,
          size,
          size.width * 0.04,
          size.height * 0.60,
          size.width * 0.18,
        );
        _drawAirplane(canvas, size, size.width * 0.82, size.height * 0.06);
        break;
      case TravelScene.registerScene:
        _drawSuitcase(
          canvas,
          size,
          size.width * 0.28,
          size.height * 0.22,
          size.width * 0.35,
        );
        _drawDestinationSigns(
          canvas,
          size,
          size.width * 0.62,
          size.height * 0.18,
        );
        _drawPalmTree(canvas, size, size.width * 0.10, size.height * 0.65);
        _drawHat(canvas, size, size.width * 0.62, size.height * 0.62);
        _drawAirplane(canvas, size, size.width * 0.72, size.height * 0.06);
        break;
    }
  }

  // ── SKY ────────────────────────────────────────────────────────────────────

  void _drawSky(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDark
                    ? [AppColors.darkSkyTop, AppColors.darkSkyBottom]
                    : [AppColors.skyTop, AppColors.skyBottom],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawStars(Canvas canvas, Size size) {
    if (!isDark) return;
    // Deterministic positions using index math (no Random — same every frame)
    final starData = [
      [0.05, 0.04],
      [0.18, 0.02],
      [0.32, 0.07],
      [0.45, 0.03],
      [0.60, 0.08],
      [0.73, 0.02],
      [0.88, 0.05],
      [0.12, 0.12],
      [0.28, 0.15],
      [0.50, 0.11],
      [0.67, 0.14],
      [0.82, 0.10],
      [0.93, 0.16],
      [0.07, 0.20],
      [0.40, 0.19],
      [0.75, 0.18],
    ];
    for (int i = 0; i < starData.length; i++) {
      final x = size.width * starData[i][0];
      final y = size.height * starData[i][1];
      // Subtle twinkle using progress
      final opacity =
          0.3 + 0.4 * math.sin((progress * 2 * math.pi) + i * 0.7).abs();
      canvas.drawCircle(
        Offset(x, y),
        size.width * (i.isEven ? 0.004 : 0.0025),
        Paint()..color = Colors.white.withAlpha((opacity * 255).round()),
      );
    }
  }

  // ── CLOUDS ─────────────────────────────────────────────────────────────────

  void _drawClouds(Canvas canvas, Size size) {
    // [cx_pct, cy_pct, scale]
    final positions = [
      [0.15, 0.07, 1.0],
      [0.58, 0.05, 0.85],
      [0.80, 0.13, 0.70],
      [0.35, 0.17, 0.65],
      [0.92, 0.06, 0.55],
    ];
    for (final p in positions) {
      _drawCloud(
        canvas,
        Offset(size.width * p[0], size.height * p[1]),
        size.width * 0.08 * p[2],
      );
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double r) {
    if (isDark) {
      // Night clouds: barely visible wisps
      final paint =
          Paint()
            ..color = const Color(0xFF1E3A5F).withAlpha((0.18 * 255).round())
            ..style = PaintingStyle.fill;
      canvas.drawCircle(center, r, paint);
      canvas.drawCircle(center.translate(r * 0.80, r * 0.10), r * 0.70, paint);
      canvas.drawCircle(center.translate(-r * 0.70, r * 0.12), r * 0.60, paint);
      canvas.drawCircle(center.translate(r * 0.40, -r * 0.28), r * 0.50, paint);
      canvas.drawCircle(
        center.translate(-r * 0.20, -r * 0.22),
        r * 0.45,
        paint,
      );
    } else {
      // Shadow
      final shadow =
          Paint()
            ..color = Colors.black.withAlpha((0.06 * 255).round())
            ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(r * 0.05, r * 0.55),
          width: r * 2.8,
          height: r * 0.55,
        ),
        shadow,
      );
      // Cloud body
      final paint =
          Paint()
            ..color = Colors.white.withAlpha((0.90 * 255).round())
            ..style = PaintingStyle.fill;
      canvas.drawCircle(center, r, paint);
      canvas.drawCircle(center.translate(r * 0.80, r * 0.10), r * 0.75, paint);
      canvas.drawCircle(center.translate(-r * 0.75, r * 0.15), r * 0.68, paint);
      canvas.drawCircle(center.translate(r * 0.42, -r * 0.32), r * 0.58, paint);
      canvas.drawCircle(
        center.translate(-r * 0.15, -r * 0.25),
        r * 0.48,
        paint,
      );
    }
  }

  // ── GLOBE ──────────────────────────────────────────────────────────────────

  void _drawGlobe(
    Canvas canvas,
    Size size, {
    required double cx,
    required double cy,
    required double r,
  }) {
    r = math.min(size.width * 0.30, size.height * 0.32);
    cy = size.height * 0.60;

    // Outer glow ring
    canvas.drawCircle(
      Offset(cx, cy),
      r + size.width * 0.04,
      Paint()
        ..color = AppColors.primary.withAlpha((0.10 * 255).round())
        ..style = PaintingStyle.fill,
    );

    // Subtle drop shadow ring
    canvas.drawCircle(
      Offset(cx, cy + r * 0.04),
      r * 1.02,
      Paint()
        ..color = Colors.black.withAlpha((0.15 * 255).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Globe body
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = AppColors.globeBlue
        ..style = PaintingStyle.fill,
    );

    // Latitude lines
    final linePaint =
        Paint()
          ..color = Colors.white.withAlpha((0.15 * 255).round())
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.003;
    final clipPath =
        Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.save();
    canvas.clipPath(clipPath);
    for (int i = -2; i <= 2; i++) {
      final y = cy + r * (i / 2.5);
      final rx2 = math.sqrt(math.max(0, r * r - (y - cy) * (y - cy)));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, y),
          width: rx2 * 2 * 0.9,
          height: r * 0.22,
        ),
        linePaint,
      );
    }
    // Meridian
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: r * 0.40, height: r * 2),
      linePaint,
    );

    // Continent blobs (simplified)
    final landPaint =
        Paint()
          ..color = AppColors.landGreen
          ..style = PaintingStyle.fill;
    // Europe/Africa
    final p1 = Path();
    p1.moveTo(cx - r * 0.05, cy - r * 0.30);
    p1.quadraticBezierTo(
      cx + r * 0.10,
      cy - r * 0.38,
      cx + r * 0.18,
      cy - r * 0.12,
    );
    p1.quadraticBezierTo(
      cx + r * 0.20,
      cy + r * 0.20,
      cx + r * 0.05,
      cy + r * 0.38,
    );
    p1.quadraticBezierTo(
      cx - r * 0.08,
      cy + r * 0.25,
      cx - r * 0.12,
      cy + r * 0.05,
    );
    p1.quadraticBezierTo(
      cx - r * 0.18,
      cy - r * 0.15,
      cx - r * 0.05,
      cy - r * 0.30,
    );
    canvas.drawPath(p1, landPaint);
    // Americas
    final p2 = Path();
    p2.moveTo(cx - r * 0.42, cy - r * 0.32);
    p2.quadraticBezierTo(
      cx - r * 0.28,
      cy - r * 0.40,
      cx - r * 0.22,
      cy - r * 0.10,
    );
    p2.quadraticBezierTo(
      cx - r * 0.20,
      cy + r * 0.18,
      cx - r * 0.30,
      cy + r * 0.40,
    );
    p2.quadraticBezierTo(
      cx - r * 0.46,
      cy + r * 0.28,
      cx - r * 0.52,
      cy + r * 0.05,
    );
    p2.quadraticBezierTo(
      cx - r * 0.55,
      cy - r * 0.18,
      cx - r * 0.42,
      cy - r * 0.32,
    );
    canvas.drawPath(p2, landPaint);
    // Asia
    final p3 = Path();
    p3.moveTo(cx + r * 0.22, cy - r * 0.38);
    p3.quadraticBezierTo(
      cx + r * 0.48,
      cy - r * 0.45,
      cx + r * 0.60,
      cy - r * 0.18,
    );
    p3.quadraticBezierTo(
      cx + r * 0.65,
      cy + r * 0.08,
      cx + r * 0.45,
      cy + r * 0.18,
    );
    p3.quadraticBezierTo(
      cx + r * 0.25,
      cy + r * 0.12,
      cx + r * 0.18,
      cy - r * 0.12,
    );
    p3.quadraticBezierTo(
      cx + r * 0.20,
      cy - r * 0.28,
      cx + r * 0.22,
      cy - r * 0.38,
    );
    canvas.drawPath(p3, landPaint);
    canvas.restore();

    // Globe border
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = AppColors.globeLineColor.withAlpha((0.40 * 255).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.003,
    );

    // Highlight
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(cx - r * 0.30, cy - r * 0.28),
        radius: r * 0.22,
      ),
      -math.pi * 0.8,
      math.pi * 0.6,
      false,
      Paint()
        ..color = Colors.white.withAlpha((0.25 * 255).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.006
        ..strokeCap = StrokeCap.round,
    );

    // Animated flight path arc
    final arcPaint =
        Paint()
          ..color = Colors.white.withAlpha((0.55 * 255).round())
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.004
          ..strokeCap = StrokeCap.round;
    final pathMetrics = _buildArcPath(cx, cy, r).computeMetrics();
    for (final m in pathMetrics) {
      final end = m.length * progress;
      final start = math.max(0.0, end - m.length * 0.35);
      canvas.drawPath(m.extractPath(start, end), arcPaint);
    }

    // Origin dot
    canvas.drawCircle(
      Offset(cx - r * 0.38, cy - r * 0.12),
      size.width * 0.012,
      Paint()..color = Colors.white,
    );
    // Destination dot
    canvas.drawCircle(
      Offset(cx + r * 0.35, cy - r * 0.28),
      size.width * 0.012,
      Paint()..color = const Color(0xFFFF6B6B),
    );
  }

  Path _buildArcPath(double cx, double cy, double r) {
    final p = Path();
    p.moveTo(cx - r * 0.38, cy - r * 0.12);
    p.cubicTo(
      cx - r * 0.10,
      cy - r * 0.70,
      cx + r * 0.10,
      cy - r * 0.70,
      cx + r * 0.35,
      cy - r * 0.28,
    );
    return p;
  }

  // ── AIRPLANE ───────────────────────────────────────────────────────────────

  void _drawAirplane(Canvas canvas, Size s, double x, double y) {
    final sc = s.width * 0.0018;
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(-math.pi / 10);

    final body = Paint()..color = Colors.white;
    final stripe = Paint()..color = const Color(0xFF2563EB);

    // Fuselage
    final bodyPath = Path();
    bodyPath.moveTo(-28 * sc, 0);
    bodyPath.quadraticBezierTo(0, -6 * sc, 32 * sc, 0);
    bodyPath.quadraticBezierTo(0, 6 * sc, -28 * sc, 0);
    canvas.drawPath(bodyPath, body);

    // Stripe
    canvas.drawRect(Rect.fromLTWH(-10 * sc, -2 * sc, 30 * sc, 4 * sc), stripe);

    // Wings
    final wing = Path();
    wing.moveTo(0, 0);
    wing.lineTo(-10 * sc, 22 * sc);
    wing.lineTo(16 * sc, 4 * sc);
    wing.close();
    canvas.drawPath(wing, body);

    // Tail
    final tail = Path();
    tail.moveTo(-22 * sc, 0);
    tail.lineTo(-28 * sc, -14 * sc);
    tail.lineTo(-12 * sc, -2 * sc);
    tail.close();
    canvas.drawPath(tail, body);

    canvas.restore();

    // Trail
    final trailPaint =
        Paint()
          ..color = Colors.white.withAlpha(
            ((isDark ? 0.35 : 0.45) * 255).round(),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.width * 0.003
          ..strokeCap = StrokeCap.round;
    final trail = Path();
    trail.moveTo(x - s.width * 0.05, y + s.height * 0.015);
    trail.quadraticBezierTo(
      x - s.width * 0.12,
      y + s.height * 0.005,
      x - s.width * 0.18,
      y - s.height * 0.010,
    );
    final metrics = trail.computeMetrics();
    for (final m in metrics) {
      canvas.drawPath(
        m.extractPath(0, m.length * ((progress * 2) % 1.0)),
        trailPaint,
      );
    }
  }

  // ── EIFFEL TOWER ───────────────────────────────────────────────────────────

  void _drawEiffelTower(Canvas canvas, Size s) {
    final x = s.width * 0.72;
    final base = s.height * 0.92;
    final h = s.height * 0.38;

    // Levels
    final levels = [
      [x - s.width * 0.055, base, x + s.width * 0.055, base - h * 0.25, 0.80],
      [
        x - s.width * 0.035,
        base - h * 0.20,
        x + s.width * 0.035,
        base - h * 0.52,
        0.70,
      ],
      [
        x - s.width * 0.018,
        base - h * 0.48,
        x + s.width * 0.018,
        base - h * 0.80,
        0.65,
      ],
      [
        x - s.width * 0.008,
        base - h * 0.77,
        x + s.width * 0.008,
        base - h * 1.00,
        0.60,
      ],
    ];
    for (final lv in levels) {
      canvas.drawPath(
        _trapezoid(lv[0], lv[1], lv[2], lv[3]),
        Paint()..color = AppColors.towerGrey.withAlpha((lv[4] * 255).round()),
      );
    }

    // Arch at base
    final archPaint =
        Paint()
          ..color = isDark ? AppColors.darkCard : Colors.white
          ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(x, base - h * 0.12),
        width: s.width * 0.050,
        height: s.height * 0.06,
      ),
      -math.pi,
      math.pi,
      true,
      archPaint,
    );
  }

  Path _trapezoid(double x1, double y1, double x2, double y2) {
    final p = Path();
    p.moveTo(x1, y1);
    p.lineTo(x2, y1);
    final midX = (x1 + x2) / 2;
    final halfTopW = (x2 - x1) * 0.3;
    p.lineTo(midX + halfTopW, y2);
    p.lineTo(midX - halfTopW, y2);
    p.close();
    return p;
  }

  // ── HOT AIR BALLOON ────────────────────────────────────────────────────────

  void _drawHotAirBalloon(Canvas canvas, Size s, double x, double y) {
    final r = s.width * 0.075;
    final floatY = y + math.sin(progress * 2 * math.pi) * s.height * 0.015;

    // Balloon
    canvas.drawCircle(
      Offset(x, floatY),
      r,
      Paint()..color = AppColors.balloonRed,
    );

    // Stripes
    final sp =
        Paint()
          ..color = Colors.white.withAlpha((0.28 * 255).round())
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.width * 0.012;
    final clip =
        Path()..addOval(Rect.fromCircle(center: Offset(x, floatY), radius: r));
    canvas.save();
    canvas.clipPath(clip);
    for (int i = -1; i <= 1; i++) {
      canvas.drawLine(
        Offset(x + i * r * 0.5, floatY - r),
        Offset(x + i * r * 0.5, floatY + r),
        sp,
      );
    }
    canvas.restore();

    // Ropes
    final rp =
        Paint()
          ..color = AppColors.signBrown.withAlpha((0.6 * 255).round())
          ..strokeWidth = s.width * 0.003;
    canvas.drawLine(
      Offset(x - r * 0.35, floatY + r * 0.85),
      Offset(x - r * 0.20, floatY + r * 1.40),
      rp,
    );
    canvas.drawLine(
      Offset(x + r * 0.35, floatY + r * 0.85),
      Offset(x + r * 0.20, floatY + r * 1.40),
      rp,
    );

    // Basket
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, floatY + r * 1.55),
          width: r * 0.55,
          height: r * 0.32,
        ),
        Radius.circular(r * 0.08),
      ),
      Paint()..color = AppColors.signBrown,
    );
  }

  // ── SUITCASE ───────────────────────────────────────────────────────────────

  void _drawSuitcase(Canvas canvas, Size s, double x, double y, double w) {
    final h = w * 1.15;
    final r = w * 0.10;

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x + w * 0.5, y + h + s.height * 0.012),
        width: w * 0.85,
        height: s.height * 0.025,
      ),
      Paint()..color = Colors.black.withAlpha((0.12 * 255).round()),
    );

    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
      Paint()..color = AppColors.suitcaseBlue,
    );

    // Stripe
    canvas.drawRect(
      Rect.fromLTWH(x, y + h * 0.44, w, h * 0.13),
      Paint()..color = AppColors.suitcaseDark,
    );

    // Handle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + w * 0.28, y - h * 0.10, w * 0.44, h * 0.12),
        Radius.circular(w * 0.05),
      ),
      Paint()
        ..color = AppColors.suitcaseDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.width * 0.008,
    );

    // Wheels
    final wheelPaint = Paint()..color = AppColors.suitcaseDark;
    canvas.drawCircle(
      Offset(x + w * 0.18, y + h + w * 0.04),
      w * 0.055,
      wheelPaint,
    );
    canvas.drawCircle(
      Offset(x + w * 0.82, y + h + w * 0.04),
      w * 0.055,
      wheelPaint,
    );

    // Lock
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + w * 0.50, y + h * 0.50),
          width: w * 0.14,
          height: w * 0.12,
        ),
        Radius.circular(w * 0.02),
      ),
      Paint()..color = Colors.white.withAlpha((0.30 * 255).round()),
    );
  }

  // ── SIGNPOST ───────────────────────────────────────────────────────────────

  void _drawSignpost(Canvas canvas, Size s, double x, double y) {
    final h = s.height * 0.35;

    // Pole
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - s.width * 0.008, y, s.width * 0.016, h),
        Radius.circular(s.width * 0.004),
      ),
      Paint()..color = AppColors.signBrown,
    );

    final signs = [
      ['EXPLORE', AppColors.signBrown, -0.05, 0.10],
      ['ADVENTURE', const Color(0xFFA16207), 0.06, 0.28],
      ['RELAX', const Color(0xFF854D0E), -0.04, 0.46],
    ];
    for (final sg in signs) {
      final sy = y + h * (sg[3] as double);
      final sw = s.width * 0.22;
      final sh = s.height * 0.048;
      final tilt = sg[2] as double;
      canvas.save();
      canvas.translate(x - sw * 0.15, sy);
      canvas.rotate(tilt * 0.20);
      // Arrow sign shape
      final sp = Path();
      sp.moveTo(0, 0);
      sp.lineTo(sw * 0.82, 0);
      sp.lineTo(sw, sh * 0.5);
      sp.lineTo(sw * 0.82, sh);
      sp.lineTo(0, sh);
      sp.close();
      canvas.drawPath(sp, Paint()..color = sg[1] as Color);
      // Text
      final tp = TextPainter(
        text: TextSpan(
          text: sg[0] as String,
          style: TextStyle(
            color: Colors.white,
            fontSize: s.width * 0.020,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(sw * 0.10, sh * 0.22));
      canvas.restore();
    }
  }

  // ── DESTINATION SIGNS ──────────────────────────────────────────────────────

  void _drawDestinationSigns(Canvas canvas, Size s, double x, double y) {
    final signs = [
      ['PARIS', AppColors.arrowBlue, 0.0, 0.0],
      ['BALI', AppColors.arrowPurple, 0.12, 0.14],
      ['DUBAI', AppColors.arrowTeal, 0.0, 0.28],
    ];
    for (final sg in signs) {
      final sx = x + s.width * (sg[2] as double);
      final sy = y + s.height * (sg[3] as double);
      final sw = s.width * 0.20;
      final sh = s.height * 0.045;
      final sp = Path();
      sp.moveTo(sx, sy);
      sp.lineTo(sx + sw * 0.80, sy);
      sp.lineTo(sx + sw, sy + sh * 0.5);
      sp.lineTo(sx + sw * 0.80, sy + sh);
      sp.lineTo(sx, sy + sh);
      sp.close();
      canvas.drawPath(sp, Paint()..color = (sg[1] as Color));
      final tp = TextPainter(
        text: TextSpan(
          text: sg[0] as String,
          style: TextStyle(
            color: Colors.white,
            fontSize: s.width * 0.022,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(sx + sw * 0.10, sy + sh * 0.22));
    }
  }

  // ── PALM TREE ──────────────────────────────────────────────────────────────

  void _drawPalmTree(Canvas canvas, Size s, double x, double y) {
    final h = s.height * 0.26;

    // Trunk (curved)
    final trunkPaint =
        Paint()
          ..color = AppColors.signBrown
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.width * 0.020
          ..strokeCap = StrokeCap.round;
    final trunk = Path();
    trunk.moveTo(x, y + h);
    trunk.cubicTo(
      x + s.width * 0.015,
      y + h * 0.7,
      x - s.width * 0.010,
      y + h * 0.3,
      x,
      y,
    );
    canvas.drawPath(trunk, trunkPaint);

    // Leaves (curved bezier arcs radiating outward)
    final leafPaint =
        Paint()
          ..color = AppColors.palmGreen
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.width * 0.015
          ..strokeCap = StrokeCap.round;

    final leafAngles = [
      [-0.90, -0.40], // far left
      [-0.50, -0.72], // left
      [0.00, -0.85], // top
      [0.50, -0.72], // right
      [0.90, -0.40], // far right
    ];

    for (final a in leafAngles) {
      final endX = x + s.width * 0.12 * a[0];
      final endY = y + s.height * 0.12 * a[1];
      final ctrlX = x + s.width * 0.06 * a[0];
      final ctrlY = y + s.height * 0.05 * a[1] - s.height * 0.02;
      final leaf = Path();
      leaf.moveTo(x, y);
      leaf.quadraticBezierTo(ctrlX, ctrlY, endX, endY);
      canvas.drawPath(leaf, leafPaint);
    }
  }

  // ── HAT ────────────────────────────────────────────────────────────────────

  void _drawHat(Canvas canvas, Size s, double x, double y) {
    final w = s.width * 0.18;
    // Brim
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, y + s.height * 0.025),
        width: w,
        height: w * 0.22,
      ),
      Paint()..color = AppColors.hatYellow,
    );
    // Crown
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, y),
          width: w * 0.60,
          height: s.height * 0.068,
        ),
        Radius.circular(w * 0.06),
      ),
      Paint()..color = AppColors.hatYellow,
    );
    // Band
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(x, y + s.height * 0.012),
        width: w * 0.60,
        height: s.height * 0.010,
      ),
      Paint()..color = AppColors.signBrown,
    );
  }

  // ── PASSPORT ───────────────────────────────────────────────────────────────

  void _drawPassport(Canvas canvas, Size s, double x, double y) {
    final w = s.width * 0.13;
    final h = w * 1.40;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        Radius.circular(w * 0.08),
      ),
      Paint()..color = AppColors.globeBlue,
    );
    canvas.drawCircle(
      Offset(x + w * 0.50, y + h * 0.38),
      w * 0.22,
      Paint()
        ..color = Colors.white.withAlpha((0.25 * 255).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.width * 0.004,
    );
  }

  // ── CAMERA ─────────────────────────────────────────────────────────────────

  void _drawCamera(Canvas canvas, Size s, double x, double y) {
    final w = s.width * 0.13;
    final h = w * 0.72;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        Radius.circular(w * 0.10),
      ),
      Paint()..color = AppColors.towerGrey,
    );
    canvas.drawCircle(
      Offset(x + w * 0.50, y + h * 0.58),
      w * 0.25,
      Paint()..color = const Color(0xFF1E293B),
    );
    canvas.drawCircle(
      Offset(x + w * 0.50, y + h * 0.58),
      w * 0.14,
      Paint()..color = const Color(0xFF0F172A),
    );
    // Flash
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + w * 0.10, y + h * 0.12, w * 0.20, h * 0.22),
        Radius.circular(w * 0.04),
      ),
      Paint()..color = Colors.white.withAlpha((0.40 * 255).round()),
    );
    // Shutter bump
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + w * 0.38, y - h * 0.14, w * 0.26, h * 0.20),
        Radius.circular(w * 0.05),
      ),
      Paint()..color = AppColors.towerGrey,
    );
  }
}
