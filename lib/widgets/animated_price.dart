import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// An animated price widget that counts up from 0 to [price] when first built.
/// Great for booking summary pages and detail screens.
class AnimatedPrice extends StatefulWidget {
  final double price;
  final String prefix;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  const AnimatedPrice({
    super.key,
    required this.price,
    this.prefix = '₹',
    this.style,
    this.duration = const Duration(milliseconds: 900),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<AnimatedPrice> createState() => _AnimatedPriceState();
}

class _AnimatedPriceState extends State<AnimatedPrice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = Tween<double>(begin: 0, end: widget.price).animate(
      CurvedAnimation(parent: _ctrl, curve: widget.curve),
    );
    // Slight delay before count-up
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void didUpdateWidget(AnimatedPrice old) {
    super.didUpdateWidget(old);
    if (old.price != widget.price) {
      _anim = Tween<double>(begin: _anim.value, end: widget.price).animate(
        CurvedAnimation(parent: _ctrl, curve: widget.curve),
      );
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Text(
          '${widget.prefix}${_anim.value.toStringAsFixed(0)}',
          style: widget.style ??
              GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
        );
      },
    );
  }
}
