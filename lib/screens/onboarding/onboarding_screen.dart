import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../main.dart';

class _PageData {
  final String imagePath;
  final String title;
  final String subtitle;
  const _PageData(this.imagePath, this.title, this.subtitle);
}

const _pages = [
  _PageData(
    'assets/mainimg1.png',
    'Explore the World',
    'Discover amazing destinations\nand unforgettable experiences.',
  ),
  _PageData(
    'assets/mainimage2.png',
    'Book Easily',
    'Flights, hotels, buses &\nholiday packages in one tap.',
  ),
  _PageData(
    'assets/mainimg3.png',
    'Enjoy Your Journey',
    'Seamless travel from start\nto finish, every time.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _ctrl = PageController();
  int _page = 0;

  // Bottom card entrance animation
  late final AnimationController _cardEntranceCtrl;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;

  // "Get Started" button pulse
  late final AnimationController _btnPulseCtrl;
  late final Animation<double> _btnPulse;

  // Page parallax
  double _pageValue = 0.0;

  @override
  void initState() {
    super.initState();

    // Card slides up on screen entry
    _cardEntranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _cardEntranceCtrl, curve: Curves.easeOutCubic));
    _cardFade = CurvedAnimation(
      parent: _cardEntranceCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    // Button pulse on last page
    _btnPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _btnPulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _btnPulseCtrl, curve: Curves.easeInOut),
    );

    // Start card entrance animation
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _cardEntranceCtrl.forward();
    });

    _ctrl.addListener(() {
      setState(() {
        _pageValue = _ctrl.page ?? 0;
      });
    });
  }

  void _goToLogin() {
    context.go('/login');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _cardEntranceCtrl.dispose();
    _btnPulseCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) {
    setState(() => _page = i);
    // Start pulsing button on last page
    if (i == _pages.length - 1) {
      _btnPulseCtrl.repeat(reverse: true);
    } else {
      _btnPulseCtrl.stop();
      _btnPulseCtrl.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final safeBot = MediaQuery.of(context).padding.bottom;

    if (size.width >= 900) {
      return Scaffold(
        body: Row(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _ctrl,
                      itemCount: _pages.length,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (_, i) => Image.asset(
                        _pages[i].imagePath,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                      ),
                    ),
                    _buildTopBar(context, isDark),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 80,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    _buildCardContent(context, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final cardH = math.max(size.height * 0.36, 260.0 + safeBot);
    final illustH = size.height;

    return Scaffold(
      body: Stack(
        children: [
          // PageView with subtle parallax
          PageView.builder(
            controller: _ctrl,
            itemCount: _pages.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (_, i) {
              // Parallax offset: image moves slower than page swipe
              final parallaxOffset = (_pageValue - i) * size.width * 0.15;
              return Transform.translate(
                offset: Offset(parallaxOffset, 0),
                child: Container(
                  alignment: Alignment.topCenter,
                  child: Image.asset(
                    _pages[i].imagePath,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    width: double.infinity,
                    height: illustH,
                  ),
                ),
              );
            },
          ),

          // Top bar
          _buildTopBar(context, isDark),

          // Bottom card with slide-up entrance
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _cardSlide,
              child: FadeTransition(
                opacity: _cardFade,
                child: Container(
                  height: cardH,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    border: isDark
                        ? null
                        : Border(
                            top: BorderSide(
                              color: Colors.grey.shade200,
                              width: 0.5,
                            ),
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.10 * 255).round()),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(
                    28,
                    28,
                    28,
                    math.max(safeBot, 20.0) + 16,
                  ),
                  child: _buildCardContent(context, isDark),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDark) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              Icon(Icons.travel_explore, color: AppColors.primary, size: 22),
              const SizedBox(width: 6),
              Text(
                'TripEase',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: R.fontSize(context, 16),
                  color: isDark ? Colors.white : AppColors.lightText,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: isDark ? Colors.white : AppColors.lightText,
              size: 22,
            ),
            onPressed: () {
              themeNotifier.value =
                  isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          if (_page < _pages.length - 1)
            TextButton(
              onPressed: _goToLogin,
              child: Text(
                'Skip',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : AppColors.lightSubtext,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title with AnimatedSwitcher fade+slide
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.2),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              ),
            );
          },
          child: Text(
            _pages[_page].title,
            key: ValueKey<int>(_page),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: R.fontSize(context, 24, tablet: 30),
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Subtitle with AnimatedSwitcher
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                    parent: animation,
                    curve: const Interval(0.2, 1.0,
                        curve: Curves.easeOutCubic))),
                child: child,
              ),
            );
          },
          child: Text(
            _pages[_page].subtitle,
            key: ValueKey<String>('sub-$_page'),
            style: GoogleFonts.poppins(
              fontSize: R.fontSize(context, 14, tablet: 16),
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              height: 1.6,
            ),
          ),
        ),

        const SizedBox(height: 30),

        Row(
          children: [
            // Animated dots
            Row(
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.only(right: 6),
                  width: i == _page ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? AppColors.primary
                        : (isDark
                            ? Colors.white24
                            : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const Spacer(),

            // Button (arrow or Get Started)
            _page < _pages.length - 1
                ? _AnimatedTapButton(
                    onTap: () => _ctrl.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                    ),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  )
                : AnimatedBuilder(
                    animation: _btnPulse,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _btnPulse.value,
                        child: child,
                      );
                    },
                    child: _AnimatedTapButton(
                      onTap: _goToLogin,
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _goToLogin,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 0),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Get Started',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ],
    );
  }
}

/// Reusable press-scale micro-interaction button wrapper
class _AnimatedTapButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _AnimatedTapButton({required this.child, required this.onTap});

  @override
  State<_AnimatedTapButton> createState() => _AnimatedTapButtonState();
}

class _AnimatedTapButtonState extends State<_AnimatedTapButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}
