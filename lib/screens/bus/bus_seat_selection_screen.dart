import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/bus_model.dart';
import '../../services/bus_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/base64_image.dart';
import '../../widgets/fullscreen_gallery.dart';
import 'passenger_details_screen.dart';

class BusSeatSelectionScreen extends StatefulWidget {
  final BusModel bus;
  const BusSeatSelectionScreen({super.key, required this.bus});

  @override
  State<BusSeatSelectionScreen> createState() =>
      _BusSeatSelectionScreenState();
}

class _BusSeatSelectionScreenState extends State<BusSeatSelectionScreen> {
  final Set<BusSeatModel> _selectedSeats = {};
  List<BusSeatModel> _allSeats = [];
  bool _isLoading = true;

  final PageController _imgCtrl = PageController();
  int _imgIndex = 0;
  late List<String> _images;

  @override
  void initState() {
    super.initState();
    _images = widget.bus.images.isNotEmpty
        ? widget.bus.images
        : (widget.bus.imageUrl != null && widget.bus.imageUrl!.isNotEmpty
            ? [widget.bus.imageUrl!]
            : []);
    _loadSeats();
    if (_images.isEmpty) _fetchImages();
  }

  Future<void> _fetchImages() async {
    try {
      final imgs = await busService.getBusImages(widget.bus.busid);
      if (mounted && imgs.isNotEmpty) setState(() => _images = imgs);
    } catch (_) {}
  }

  @override
  void dispose() {
    _imgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSeats() async {
    try {
      final data = await busService.getBusSeats(widget.bus.busid);
      if (data.isEmpty) throw Exception('No seats');
      setState(() {
        _allSeats = data.map((s) => BusSeatModel.fromJson(s)).toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _allSeats = [];
        _isLoading = false;
      });
    }
  }

  void _toggleSeat(BusSeatModel seat) {
    if (seat.isBooked) return;
    setState(() {
      if (_selectedSeats.any((s) => s.seatid == seat.seatid)) {
        _selectedSeats.removeWhere((s) => s.seatid == seat.seatid);
      } else {
        if (_selectedSeats.length >= 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 6 seats can be selected')),
          );
          return;
        }
        _selectedSeats.add(seat);
      }
    });
  }

  double get _totalFare => _selectedSeats.fold(
      0, (sum, s) => sum + widget.bus.baseFare + s.extraFare);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: _images.isNotEmpty ? 340 : 140,
                  pinned: true,
                  stretch: true,
                  backgroundColor: const Color(0xFF1E293B),
                  leading: Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      backgroundColor: Colors.black38,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground],
                    background: _buildHero(isDark),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildInfoStrip(isDark),
                      _buildLegend(isDark),
                      _buildSeatLayout(isDark),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
      bottomSheet: _isLoading ? null : _buildBottomBar(isDark),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────

  Widget _buildHero(bool isDark) {
    if (_images.isEmpty) return _gradientFallback();

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_images.length == 1)
          GestureDetector(
            onTap: () => openFullscreenGallery(context, _images, initialIndex: 0),
            child: Base64Image(base64String: _images.first, fit: BoxFit.cover),
          )
        else
          PageView.builder(
            controller: _imgCtrl,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) => setState(() => _imgIndex = i),
            itemCount: _images.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => openFullscreenGallery(context, _images, initialIndex: i),
              child: Base64Image(base64String: _images[i], fit: BoxFit.cover),
            ),
          ),
        // Scrim
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withAlpha(10),
                Colors.transparent,
                Colors.black.withAlpha(200),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        // Bus name + route at bottom
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.bus.busName,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(
                        color: Colors.black.withAlpha(160), blurRadius: 8)
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _heroBadge(
                    '${widget.bus.sourceCityName ?? 'Source'} → ${widget.bus.destinationCityName ?? 'Dest'}',
                    Icons.route_rounded,
                  ),
                  const SizedBox(width: 8),
                  _heroBadge(widget.bus.busType, Icons.directions_bus_rounded),
                  const Spacer(),
                  if (_images.length > 1)
                    Row(
                      children: List.generate(
                        _images.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _imgIndex == i ? 16 : 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: _imgIndex == i
                                ? Colors.white
                                : Colors.white.withAlpha(110),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _gradientFallback() {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6D28D9), Color(0xFFC026D3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Center(
          child: Icon(Icons.directions_bus_rounded,
              size: 90, color: Colors.white.withAlpha(60)),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.bus.busName,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(children: [
                _heroBadge(
                    '${widget.bus.sourceCityName ?? 'Source'} → ${widget.bus.destinationCityName ?? 'Dest'}',
                    Icons.route_rounded),
                const SizedBox(width: 8),
                _heroBadge(widget.bus.busType, Icons.directions_bus_rounded),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  // ── Info strip ──────────────────────────────────────────────────────────

  Widget _buildInfoStrip(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _infoItem(Icons.schedule_rounded,
              widget.bus.departureTime.length >= 5
                  ? widget.bus.departureTime.substring(0, 5)
                  : widget.bus.departureTime,
              'Departure', isDark),
          _divider(),
          _infoItem(Icons.schedule_rounded,
              widget.bus.arrivalTime.length >= 5
                  ? widget.bus.arrivalTime.substring(0, 5)
                  : widget.bus.arrivalTime,
              'Arrival', isDark),
          _divider(),
          _infoItem(Icons.event_seat_rounded,
              '${widget.bus.totalSeats}', 'Total Seats', isDark),
          _divider(),
          _infoItem(Icons.currency_rupee_rounded,
              widget.bus.baseFare.toStringAsFixed(0), 'Base Fare', isDark),
        ],
      ),
    );
  }

  Widget _infoItem(
      IconData icon, String value, String label, bool isDark) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF8B5CF6)),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF1E293B))),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10, color: const Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 36, color: const Color(0xFFE2E8F0));
  }

  // ── Legend ──────────────────────────────────────────────────────────────

  Widget _buildLegend(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _legendItem(
                isDark ? Colors.white10 : Colors.white,
                'Available',
                true,
                isDark),
            _legendItem(const Color(0xFF8B5CF6), 'Selected', false, isDark),
            _legendItem(
                isDark ? Colors.white24 : Colors.grey[300]!,
                'Booked',
                false,
                isDark),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(
      Color color, String text, bool hasBorder, bool isDark) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
            border: hasBorder
                ? Border.all(color: Colors.grey.shade400)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF475569))),
      ],
    );
  }

  // ── Seat layout ──────────────────────────────────────────────────────────

  Widget _buildSeatLayout(bool isDark) {
    int maxRows = _allSeats.fold(0, (m, s) => s.rowNo > m ? s.rowNo : m);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          children: [
            // Driver indicator
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.radio_button_checked_rounded,
                        size: 16, color: Color(0xFF8B5CF6)),
                    const SizedBox(width: 4),
                    Text('Driver',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8B5CF6))),
                  ],
                ),
              ),
            ),
            for (int r = 1; r <= maxRows; r++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSeat(r, 1, isDark),
                    _buildSeat(r, 2, isDark),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: 20,
                        child: Divider(
                          color: isDark
                              ? Colors.white12
                              : Colors.grey.shade200,
                        ),
                      ),
                    ),
                    _buildSeat(r, 3, isDark),
                    _buildSeat(r, 4, isDark),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeat(int row, int col, bool isDark) {
    final idx =
        _allSeats.indexWhere((s) => s.rowNo == row && s.colNo == col);
    if (idx == -1) {
      return const SizedBox(width: 40, height: 40);
    }
    final seat = _allSeats[idx];
    final isSelected = _selectedSeats.any((s) => s.seatid == seat.seatid);

    Color bg;
    Color border;
    Color textColor;

    if (seat.isBooked) {
      bg = isDark ? Colors.white10 : Colors.grey.shade200;
      border = Colors.transparent;
      textColor = Colors.grey;
    } else if (isSelected) {
      bg = const Color(0xFF8B5CF6);
      border = const Color(0xFF7C3AED);
      textColor = Colors.white;
    } else {
      bg = isDark ? const Color(0xFF334155) : Colors.white;
      border = isDark ? Colors.white12 : Colors.grey.shade300;
      textColor = isDark ? Colors.white70 : Colors.black87;
    }

    return GestureDetector(
      onTap: () => _toggleSeat(seat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withAlpha(80),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          seat.seatNo,
          style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: textColor),
        ),
      ),
    );
  }

  // ── Bottom bar ──────────────────────────────────────────────────────────

  Widget _buildBottomBar(bool isDark) {
    final hasSelection = _selectedSeats.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 24,
            offset: const Offset(0, -8),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Fare info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_selectedSeats.length} seat${_selectedSeats.length == 1 ? '' : 's'} selected',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8)),
                ),
                Text(
                  '₹${_totalFare.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Confirm button
            GestureDetector(
              onTap: hasSelection
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PassengerDetailsScreen(
                            bus: widget.bus,
                            selectedSeats: _selectedSeats.toList(),
                          ),
                        ),
                      );
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 16),
                decoration: BoxDecoration(
                  gradient: hasSelection
                      ? const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        )
                      : null,
                  color: hasSelection ? null : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: hasSelection
                      ? [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withAlpha(100),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  'Confirm Booking',
                  style: GoogleFonts.poppins(
                    color: hasSelection ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
