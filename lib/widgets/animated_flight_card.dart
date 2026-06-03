import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/flight_model.dart';

class AnimatedFlightCard extends StatefulWidget {
  final FlightModel flight;
  final Duration delay;

  const AnimatedFlightCard({
    super.key,
    required this.flight,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedFlightCard> createState() => _AnimatedFlightCardState();
}

class _AnimatedFlightCardState extends State<AnimatedFlightCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _planeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _planeAnim = Tween<double>(begin: -0.2, end: 1.2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.flight.airline,
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                '₹${widget.flight.price.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.flight.departureTime.split(' ').last.substring(0, 5),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      widget.flight.fromCityName ?? 'From',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        LayoutBuilder(builder: (context, constraints) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              (constraints.maxWidth / 8).floor(),
                              (index) => Container(
                                width: 4,
                                height: 2,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                          );
                        }),
                        AnimatedBuilder(
                          animation: _planeAnim,
                          builder: (context, child) {
                            return Align(
                              alignment: Alignment(
                                _planeAnim.value.clamp(-1.0, 1.0),
                                0,
                              ),
                              child: Opacity(
                                opacity: (_planeAnim.value > -0.2 && _planeAnim.value < 1.2) ? 1.0 : 0.0,
                                child: const Icon(
                                  Icons.flight_takeoff_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.flight.duration,
                      style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.flight.arrivalTime.split(' ').last.substring(0, 5),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      widget.flight.toCityName ?? 'To',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
