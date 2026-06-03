import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

/// The booking success celebration screen.
/// Shows after a successful payment/booking with:
/// - Confetti particle burst
/// - Animated checkmark (circle draws then check draws)
/// - Floating emoji particles (✈️ 🏖️ 🎉)
/// - Booking details card sliding up
/// - Optional "You saved ₹X" bounce-in badge
class BookingSuccessScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? savedAmount;
  final String? bookingType; // 'hotel' | 'bus' | 'flight' | 'package'
  final VoidCallback? onDone;

  const BookingSuccessScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.savedAmount,
    this.bookingType,
    this.onDone,
  });

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with TickerProviderStateMixin {
  // Checkmark drawing
  late final AnimationController _checkCtrl;
  late final Animation<double> _circleProgress;
  late final Animation<double> _checkProgress;
  late final Animation<double> _checkScale;

  // Confetti
  late final AnimationController _confettiCtrl;

  // Card slide-up
  late final AnimationController _cardCtrl;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;

  // Savings badge bounce
  late final AnimationController _badgeCtrl;
  late final Animation<double> _badgeBounce;

  // Emoji floaters
  late final AnimationController _emojiCtrl;

  // Background fade
  late final AnimationController _bgCtrl;
  late final Animation<double> _bgFade;

  final List<_Particle> _particles = [];
  final List<_EmojiParticle> _emojis = [];
  final _random = _Rng();

  static const _emojis_ = ['✈️', '🏖️', '🎉', '🌟', '🎊', '🗺️', '🏨'];

  @override
  void initState() {
    super.initState();

    _generateParticles();
    _generateEmojis();

    // Background reveal
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _bgFade = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeIn);

    // Confetti burst (0 → 1 in 2s, then stays)
    _confettiCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));

    // Checkmark: circle 0→1 in 600ms, check 0→1 in 400ms after
    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _circleProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _checkCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _checkProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _checkCtrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _checkScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );

    // Card slide up
    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeIn);

    // Badge bounce
    _badgeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _badgeBounce = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _badgeCtrl, curve: Curves.elasticOut),
    );

    // Emoji float
    _emojiCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500));

    _runSequence();
  }

  void _generateParticles() {
    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF8B5CF6),
      const Color(0xFFEF4444),
      const Color(0xFF06B6D4),
      Colors.white,
    ];
    for (int i = 0; i < 60; i++) {
      _particles.add(_Particle(
        x: 0.5 + (_random.nextDouble() - 0.5) * 0.1,
        y: 0.35,
        vx: (_random.nextDouble() - 0.5) * 1.2,
        vy: -(_random.nextDouble() * 1.0 + 0.4),
        color: colors[_random.nextInt(colors.length)],
        size: _random.nextDouble() * 8 + 4,
        rotation: _random.nextDouble() * 6.28,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.2,
        isRect: i % 3 != 0,
      ));
    }
  }

  void _generateEmojis() {
    for (int i = 0; i < 8; i++) {
      _emojis.add(_EmojiParticle(
        emoji: _emojis_[_random.nextInt(_emojis_.length)],
        x: _random.nextDouble(),
        startDelay: _random.nextDouble() * 0.5,
        size: _random.nextDouble() * 16 + 16,
      ));
    }
  }

  Future<void> _runSequence() async {
    _bgCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _confettiCtrl.forward();
    _checkCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _emojiCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _cardCtrl.forward();
    if (widget.savedAmount != null) {
      await Future.delayed(const Duration(milliseconds: 400));
      _badgeCtrl.forward();
    }
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _confettiCtrl.dispose();
    _cardCtrl.dispose();
    _badgeCtrl.dispose();
    _emojiCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  IconData get _bookingIcon {
    switch (widget.bookingType) {
      case 'hotel':
        return Icons.hotel_rounded;
      case 'bus':
        return Icons.directions_bus_rounded;
      case 'flight':
        return Icons.flight_rounded;
      case 'package':
        return Icons.luggage_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  String get _bookingLabel {
    switch (widget.bookingType) {
      case 'hotel':
        return 'Hotel Booking';
      case 'bus':
        return 'Bus Ticket';
      case 'flight':
        return 'Flight Ticket';
      case 'package':
        return 'Tour Package';
      default:
        return 'Booking';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: FadeTransition(
          opacity: _bgFade,
          child: Stack(
            children: [
              // ── Gradient background ──────────────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0F172A),
                      Color(0xFF1E293B),
                    ],
                  ),
                ),
              ),

              // ── Confetti ─────────────────────────────────────────────────
              AnimatedBuilder(
                animation: _confettiCtrl,
                builder: (_, __) {
                  return CustomPaint(
                    size: size,
                    painter: _ConfettiPainter(
                      particles: _particles,
                      progress: _confettiCtrl.value,
                    ),
                  );
                },
              ),

              // ── Emoji floaters ────────────────────────────────────────────
              AnimatedBuilder(
                animation: _emojiCtrl,
                builder: (_, __) {
                  return Stack(
                    children: _emojis.map((e) {
                      final t = ((_emojiCtrl.value - e.startDelay) /
                              (1.0 - e.startDelay))
                          .clamp(0.0, 1.0);
                      final y = size.height * 0.7 - t * size.height * 0.55;
                      final opacity = (1.0 - (t - 0.6).clamp(0.0, 1.0) / 0.4);
                      return Positioned(
                        left: e.x * size.width,
                        top: y,
                        child: Opacity(
                          opacity: opacity,
                          child: Text(
                            e.emoji,
                            style: TextStyle(fontSize: e.size),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              // ── Main Content ─────────────────────────────────────────────
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 48),

                    // Animated Checkmark
                    AnimatedBuilder(
                      animation: _checkCtrl,
                      builder: (_, __) {
                        return Transform.scale(
                          scale: _checkScale.value,
                          child: SizedBox(
                            width: 120,
                            height: 120,
                            child: CustomPaint(
                              painter: _CheckmarkPainter(
                                circleProgress: _circleProgress.value,
                                checkProgress: _checkProgress.value,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Title
                    AnimatedBuilder(
                      animation: _cardFade,
                      builder: (_, __) => FadeTransition(
                        opacity: _cardFade,
                        child: Text(
                          widget.title,
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    FadeTransition(
                      opacity: _cardFade,
                      child: Text(
                        widget.subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.white60,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Details card slides up
                    SlideTransition(
                      position: _cardSlide,
                      child: FadeTransition(
                        opacity: _cardFade,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildDetailsCard(context),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Savings badge bounces in
                    if (widget.savedAmount != null)
                      ScaleTransition(
                        scale: _badgeBounce,
                        child: _buildSavingsBadge(),
                      ),

                    const Spacer(),

                    // Done button
                    FadeTransition(
                      opacity: _cardFade,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 24),
                        child: _buildDoneButton(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Booking type icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(_bookingIcon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            _bookingLabel,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF10B981),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Booking Confirmed!',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.check_circle_outline_rounded, 'Status',
              'Confirmed', const Color(0xFF10B981)),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.receipt_long_rounded, 'Payment', 'Successful',
              const Color(0xFF2563EB)),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.email_outlined, 'Confirmation',
              'Sent to your email', Colors.white60),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, Color valueColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white38),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.white54),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSavingsBadge() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            'You saved ₹${widget.savedAmount}!',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          const Text('🎉', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildDoneButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          widget.onDone?.call();
          context.go('/bookings');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Back to Home',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.home_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Checkmark Painter ────────────────────────────────────────────────────────

class _CheckmarkPainter extends CustomPainter {
  final double circleProgress;
  final double checkProgress;

  _CheckmarkPainter({
    required this.circleProgress,
    required this.checkProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Draw glow
    final glowPaint = Paint()
      ..color = const Color(0xFF10B981).withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, radius + 8, glowPaint);

    // Circle arc
    final circlePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -1.5708, // start at top (12 o'clock)
      2 * 3.14159 * circleProgress,
      false,
      circlePaint,
    );

    // Fill circle with slight green tint when complete
    if (circleProgress >= 1.0) {
      final fillPaint = Paint()
        ..color = const Color(0xFF10B981).withOpacity(0.15);
      canvas.drawCircle(center, radius, fillPaint);
    }

    // Draw checkmark
    if (checkProgress > 0) {
      final checkPaint = Paint()
        ..color = const Color(0xFF10B981)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Checkmark path: left leg + right leg
      final p1 = Offset(size.width * 0.28, size.height * 0.52);
      final p2 = Offset(size.width * 0.44, size.height * 0.66);
      final p3 = Offset(size.width * 0.72, size.height * 0.36);

      final totalLen = (p2 - p1).distance + (p3 - p2).distance;
      final drawn = totalLen * checkProgress;

      final path = Path();
      path.moveTo(p1.dx, p1.dy);

      final seg1Len = (p2 - p1).distance;
      if (drawn <= seg1Len) {
        final t = drawn / seg1Len;
        path.lineTo(
          p1.dx + (p2.dx - p1.dx) * t,
          p1.dy + (p2.dy - p1.dy) * t,
        );
      } else {
        path.lineTo(p2.dx, p2.dy);
        final remaining = drawn - seg1Len;
        final seg2Len = (p3 - p2).distance;
        final t = (remaining / seg2Len).clamp(0.0, 1.0);
        path.lineTo(
          p2.dx + (p3.dx - p2.dx) * t,
          p2.dy + (p3.dy - p2.dy) * t,
        );
      }

      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(_CheckmarkPainter old) =>
      old.circleProgress != circleProgress ||
      old.checkProgress != checkProgress;
}

// ── Confetti Painter ─────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final t = (progress - p.startDelay).clamp(0.0, 1.0);
      if (t <= 0) continue;

      // Physics: gravity + initial velocity
      final x = p.x * size.width + p.vx * t * size.width * 0.3;
      final y = p.y * size.height +
          p.vy * t * size.height * 0.4 +
          0.5 * 980 * t * t * 0.2;

      // Fade out near end
      final opacity = (1.0 - (t - 0.6).clamp(0.0, 1.0) / 0.4)
          .clamp(0.0, 1.0);

      if (opacity <= 0) continue;

      paint.color = p.color.withOpacity(opacity * 0.9);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + p.rotationSpeed * t * 10);

      if (p.isRect) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero, width: p.size, height: p.size * 0.5),
            const Radius.circular(2),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.size * 0.5, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

// ── Data Models ───────────────────────────────────────────────────────────────

class _Particle {
  final double x, y, vx, vy;
  final Color color;
  final double size, rotation, rotationSpeed;
  final bool isRect;
  final double startDelay;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.isRect,
  }) : startDelay = 0.0;
}

class _EmojiParticle {
  final String emoji;
  final double x;
  final double startDelay;
  final double size;

  _EmojiParticle({
    required this.emoji,
    required this.x,
    required this.startDelay,
    required this.size,
  });
}

// Simple pseudo-random number generator (no dart:math import needed)
class _Rng {
  int _seed = 42;

  double nextDouble() {
    _seed = (_seed * 1664525 + 1013904223) & 0xFFFFFFFF;
    return _seed / 0xFFFFFFFF;
  }

  int nextInt(int max) => (nextDouble() * max).floor();
}
