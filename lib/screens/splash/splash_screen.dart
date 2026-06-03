import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/role_constants.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  final String? targetPath;
  const SplashScreen({super.key, this.targetPath});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Icon scale-in (elastic spring) ──────────────────────────────────────
  late final AnimationController _iconCtrl;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconFade;

  // ── Title slide-up + fade ────────────────────────────────────────────────
  late final AnimationController _titleCtrl;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;

  // ── Tagline fade ─────────────────────────────────────────────────────────
  late final AnimationController _tagCtrl;
  late final Animation<double> _tagFade;

  // ── Pulse ring (radiating glow) ──────────────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  // ── Background gradient animation ────────────────────────────────────────
  late final AnimationController _bgCtrl;
  late final Animation<double> _bgAnim;

  @override
  void initState() {
    super.initState();

    // Icon: 0 → 1.0, elastic, 700ms
    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _iconScale = CurvedAnimation(
      parent: _iconCtrl,
      curve: Curves.elasticOut,
    );
    _iconFade = CurvedAnimation(
      parent: _iconCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    // Title: fade + slide, delayed 400ms
    _titleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _titleFade = CurvedAnimation(
      parent: _titleCtrl,
      curve: Curves.easeOut,
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _titleCtrl, curve: Curves.easeOutCubic));

    // Tagline: fade only, delayed 700ms
    _tagCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _tagFade = CurvedAnimation(parent: _tagCtrl, curve: Curves.easeIn);

    // Pulse ring: repeating scale + fade
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pulseScale = Tween<double>(begin: 0.8, end: 2.2).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );

    // Background gradient shift
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    _runSequence();
  }

  Future<void> _runSequence() async {
    // Start background immediately
    _bgCtrl.forward();

    // Icon springs in
    await Future.delayed(const Duration(milliseconds: 100));
    _iconCtrl.forward();

    // Pulse ring starts after icon appears and repeats
    await Future.delayed(const Duration(milliseconds: 400));
    _pulseCtrl.repeat();

    // Title slides up
    await Future.delayed(const Duration(milliseconds: 200));
    _titleCtrl.forward();

    // Tagline fades in
    await Future.delayed(const Duration(milliseconds: 300));
    _tagCtrl.forward();

    // Check session and navigate
    await _checkSession();
  }

  Future<void> _checkSession() async {
    await authService.initSession();
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    if (authService.currentUser != null) {
      if (widget.targetPath != null && widget.targetPath!.isNotEmpty) {
        context.go(widget.targetPath!);
      } else {
        final user = authService.currentUser!;
        context.go(routeByRole(roleId: user.roleid, roleName: user.rolename));
      }
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _iconCtrl.dispose();
    _titleCtrl.dispose();
    _tagCtrl.dispose();
    _pulseCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgAnim,
      builder: (context, _) {
        // Smoothly shift between two gradient positions
        final t = _bgAnim.value;
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: const [
                  Color(0xFF1D4ED8),
                  Color(0xFF2563EB),
                  Color(0xFF3B82F6),
                ],
                stops: [0.0, 0.5 + t * 0.2, 1.0],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Decorative background circles ──────────────────────────
                Positioned(
                  top: -80 + t * 20,
                  right: -60,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -100 + t * -20,
                  left: -80,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),

                // ── Main content ───────────────────────────────────────────
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon with pulse ring
                    AnimatedBuilder(
                      animation: Listenable.merge(
                          [_pulseScale, _pulseOpacity, _iconScale, _iconFade]),
                      builder: (context, _) {
                        return SizedBox(
                          width: 140,
                          height: 140,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer pulse ring 1
                              Transform.scale(
                                scale: _pulseScale.value,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(
                                          _pulseOpacity.value * 0.6),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              // Inner pulse ring 2 (half-phase offset)
                              Transform.scale(
                                scale: _pulseScale.value * 0.7,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(
                                          _pulseOpacity.value * 0.9),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              // Icon with glass-morphism background
                              FadeTransition(
                                opacity: _iconFade,
                                child: ScaleTransition(
                                  scale: _iconScale,
                                  child: Container(
                                    width: 88,
                                    height: 88,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.15),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              Colors.black.withOpacity(0.15),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.travel_explore_rounded,
                                      size: 46,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    // App name with slide + fade
                    SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(
                        opacity: _titleFade,
                        child: const Text(
                          'TripEase',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Tagline fade-in
                    FadeTransition(
                      opacity: _tagFade,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTagDot(),
                          const SizedBox(width: 8),
                          const Text(
                            'Book. Pack. Go.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildTagDot(),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Bottom loading dots ────────────────────────────────────
                Positioned(
                  bottom: 60,
                  child: FadeTransition(
                    opacity: _tagFade,
                    child: _LoadingDots(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTagDot() {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.5),
      ),
    );
  }
}

/// Three bouncing dots loading indicator
class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    _anims = _controllers.map((c) {
      return Tween<double>(begin: 0, end: -10).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    // Staggered start
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) {
            return Transform.translate(
              offset: Offset(0, _anims[i].value),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
