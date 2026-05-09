import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
// Note: Since you're not using 'app_colors.dart', we define our colors in the widget directly.
import '../../services/agent_service.dart';

class AddEditPackageScreen extends StatefulWidget {
  // isEdit=false → Add mode. isEdit=true → Edit mode.
  final bool isEdit;
  // For edit mode, pass existing package data
  final Map<String, dynamic>? packageData;
  // partnerid and userid from session
  final int partnerid;
  final int userid;

  const AddEditPackageScreen({
    super.key,
    this.isEdit = false,
    this.packageData,
    required this.partnerid,
    required this.userid,
  });

  @override
  State<AddEditPackageScreen> createState() => _AddEditPackageScreenState();
}

class _AddEditPackageScreenState extends State<AddEditPackageScreen> {

  // ── Form key ──────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  // ── Controllers ──────────────────────────────────────────────────────────
  final _nameCtrl        = TextEditingController();
  final _descCtrl        = TextEditingController();
  final _priceCtrl       = TextEditingController();
  final _daysCtrl        = TextEditingController();
  final _nightsCtrl      = TextEditingController();
  final _maxPersonsCtrl  = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];

  // ── State ─────────────────────────────────────────────────────────────────
  List<CategoryItem>     _categories      = [];
  List<CityItem>         _cities          = [];
  List<ItineraryDayItem> _itinerary       = [];
  CategoryItem?          _selectedCategory;
  CityItem?              _selectedCity;
  bool                   _loadingDropdowns = true;
  bool                   _saving           = false;
  String?                _errorMessage;

  // ── Responsive helpers ───────────────────────────────────────────────────
  bool get _isMobile  => MediaQuery.of(context).size.width < 600;
  bool get _isTablet  => MediaQuery.of(context).size.width >= 600
                      && MediaQuery.of(context).size.width < 1024;
  bool get _isDesktop => MediaQuery.of(context).size.width >= 1024;
  double get _hPad    => _isDesktop ? 48.0 : _isTablet ? 32.0 : 20.0;

  // ── Colors ────────────────────────────────────────────────────────────────
  static const _primary    = Color(0xFF2563EB);
  static const _error      = Color(0xFFEF4444);
  static const _success    = Color(0xFF10B981);
  static const _bgLight    = Color(0xFFEFF6FF);
  static const _cardLight  = Color(0xFFFFFFFF);
  static const _textPri    = Color(0xFF1E293B);
  static const _textSub    = Color(0xFF64748B);
  static const _inputBorder= Color(0xFFE2E8F0);
  static const _inputFill  = Color(0xFFF8FAFC);
  // Itinerary day accent colors (cycles)
  static const _dayColors  = [
    Color(0xFF2563EB), Color(0xFF059669), Color(0xFF7C3AED),
    Color(0xFFDB2777), Color(0xFFD97706), Color(0xFF0891B2),
  ];

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
    if (widget.isEdit && widget.packageData != null) {
      _prefillForEdit(widget.packageData!);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();       _descCtrl.dispose();
    _priceCtrl.dispose();      _daysCtrl.dispose();
    _nightsCtrl.dispose();     _maxPersonsCtrl.dispose();
    super.dispose();
  }

  // ── Load dropdowns ────────────────────────────────────────────────────────
  Future<void> _loadDropdowns() async {
    try {
      final results = await Future.wait([
        AgentService.getCategories(),
        AgentService.getCities(),
      ]);
      if (!mounted) return;
      setState(() {
        _categories       = results[0] as List<CategoryItem>;
        _cities           = results[1] as List<CityItem>;
        _loadingDropdowns = false;
      });
      // If edit mode, match the IDs to dropdown items
      if (widget.isEdit && widget.packageData != null) {
        final catId  = int.tryParse(
            widget.packageData!['categoryid'].toString()) ?? 0;
        final cityId = int.tryParse(
            widget.packageData!['cityid'].toString()) ?? 0;
        setState(() {
          _selectedCategory = _categories
              .where((c) => c.categoryid == catId)
              .firstOrNull;
          _selectedCity = _cities
              .where((c) => c.cityid == cityId)
              .firstOrNull;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingDropdowns = false;
        _errorMessage     = 'Failed to load form data: $e';
      });
    }
  }

  // ── Pre-fill for edit ─────────────────────────────────────────────────────
  void _prefillForEdit(Map<String, dynamic> d) {
    _nameCtrl.text       = d['packagename']  ?? '';
    _descCtrl.text       = d['description']  ?? '';
    _priceCtrl.text      = d['price']?.toString() ?? '';
    _daysCtrl.text       = d['days']?.toString()  ?? '';
    _nightsCtrl.text     = d['nights']?.toString() ?? '';
    _maxPersonsCtrl.text = d['maxpersons']?.toString() ?? '';

    if (d['itinerary'] is List) {
      _itinerary = (d['itinerary'] as List)
          .map((e) => ItineraryDayItem.fromJson(e))
          .toList();
    }
  }

  // ── Auto-sync nights when days changes ────────────────────────────────────
  void _onDaysChanged(String val) {
    final d = int.tryParse(val);
    if (d != null && d > 0) {
      setState(() {
        _nightsCtrl.text = (d - 1).toString();
        // Resize itinerary list
        while (_itinerary.length < d) {
          _itinerary.add(ItineraryDayItem(
            dayno:       _itinerary.length + 1,
            title:       '',
            description: '',
          ));
        }
        while (_itinerary.length > d) {
          _itinerary.removeLast();
        }
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> picked = await _picker.pickMultiImage(
        maxWidth: 800,
        imageQuality: 70,
      );
      if (picked.isNotEmpty) {
        if (_selectedImages.length + picked.length > 5) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Max 5 images allowed')));
          return;
        }
        setState(() {
          _selectedImages.addAll(picked);
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking images: $e')));
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<List<String>> _processImages() async {
    List<String> base64Images = [];
    for (var file in _selectedImages) {
      final bytes = await file.readAsBytes();
      base64Images.add(base64Encode(bytes));
    }
    return base64Images;
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      setState(() => _errorMessage = 'Please select a category');
      return;
    }
    if (_selectedCity == null) {
      setState(() => _errorMessage = 'Please select a destination city');
      return;
    }

    // Validate itinerary titles for all days
    for (final day in _itinerary) {
      if (day.title.trim().isEmpty) {
        setState(() => _errorMessage =
            'Please fill in the title for Day ${day.dayno}');
        return;
      }
    }

    setState(() => _saving = true);

    try {
      List<String>? base64Images;
      if (_selectedImages.isNotEmpty) {
        base64Images = await _processImages();
      }

      final payload = {
        'partnerid':   widget.partnerid,
        'uid':         widget.userid,
        'packageid':   widget.isEdit
            ? int.parse(widget.packageData!['packageid'].toString())
            : 0,
        'categoryid':  _selectedCategory!.categoryid,
        'packagename': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'cityid':      _selectedCity!.cityid,
        'days':        int.parse(_daysCtrl.text.trim()),
        'nights':      int.parse(_nightsCtrl.text.trim()),
        'price':       double.parse(_priceCtrl.text.trim()),
        'maxpersons':  int.parse(_maxPersonsCtrl.text.trim()),
        'itinerary':   _itinerary,
      };

      if (base64Images != null) {
        payload['images'] = base64Images;
      }

      final packageid = await AgentService.savePackageRaw(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEdit
                ? 'Package updated successfully!'
                : 'Package added successfully! (ID: $packageid)',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: _success,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context, true); // true = refresh list

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving       = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  // ── Add New City Dialog ───────────────────────────────────────────────────
  Future<void> _showAddCityDialog(bool isDark) async {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSavingCity = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF142035) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Add New City', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: isDark ? Colors.white : _textPri)),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: ctrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: _fieldDecoration('City Name *', icon: Icons.location_city_rounded),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'City name is required';
                    return null;
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSavingCity ? null : () => Navigator.pop(ctx),
                  child: Text('Cancel', style: GoogleFonts.poppins(color: _textSub)),
                ),
                ElevatedButton(
                  onPressed: isSavingCity
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setStateDialog(() => isSavingCity = true);
                          try {
                            final newCity = await AgentService.addCity(ctrl.text.trim(), widget.userid);
                            // Update the main screen state
                            setState(() {
                              // Prevent duplicates if already exists
                              if (!_cities.any((c) => c.cityid == newCity.cityid)) {
                                _cities.add(newCity);
                                _cities.sort((a, b) => a.cityname.compareTo(b.cityname));
                              }
                              _selectedCity = _cities.firstWhere((c) => c.cityid == newCity.cityid);
                            });
                            if (mounted) Navigator.pop(ctx);
                          } catch (e) {
                            setStateDialog(() => isSavingCity = false);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Failed: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: _error)
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSavingCity
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Add City', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Input decoration ──────────────────────────────────────────────────────
  InputDecoration _fieldDecoration(String label, {
    IconData? icon,
    String? hint,
    Widget? suffix,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText:      label,
      hintText:       hint,
      prefixIcon:     icon != null ? Icon(icon, color: _primary, size: 20) : null,
      suffixIcon:     suffix,
      filled:         true,
      fillColor:      isDark ? const Color(0xFF1E3A5F) : _inputFill,
      labelStyle:     GoogleFonts.poppins(fontSize: 13, color: _textSub),
      hintStyle:      GoogleFonts.poppins(fontSize: 13, color: _textSub),
      border:         OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _inputBorder)),
      enabledBorder:  OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark
                  ? _primary.withOpacity(0.25)
                  : _inputBorder)),
      focusedBorder:  OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.5)),
      errorBorder:    OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _error)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _error, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ── Section header ────────────────────────────────────────────────────────
  Widget _sectionHeader(String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 12),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _primary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: _primary, size: 18),
      ),
      const SizedBox(width: 10),
      Text(title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _textPri,
        )),
      const SizedBox(width: 12),
      const Expanded(child: Divider(color: _inputBorder)),
    ]),
  );

  // ── Itinerary Day Card ────────────────────────────────────────────────────
  Widget _buildItineraryDayCard(int index) {
    return _ItineraryDayCard(
      key: ValueKey(_itinerary[index].dayno),
      day: _itinerary[index],
      color: _dayColors[index % _dayColors.length],
      isFirst: index == 0,
      fieldDecorationBuilder: _fieldDecoration,
    );
  }

  // ── Main BUILD ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A1628) : _bgLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF142035) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : _textPri, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isEdit ? 'Edit Package' : 'Add New Package',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : _textPri,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1,
              color: isDark ? Colors.white12 : _inputBorder),
        ),
      ),
      body: _loadingDropdowns
          ? const Center(child: CircularProgressIndicator(
              color: _primary, strokeWidth: 2.5))
          : _buildForm(isDark),
    );
  }

  Widget _buildForm(bool isDark) {
    // On desktop: two-column layout
    return Form(
      key: _formKey,
      child: _isDesktop
          ? _buildDesktopLayout(isDark)
          : _buildMobileLayout(isDark),
    );
  }

  // ── DESKTOP: Left column (details) + Right column (itinerary) ────────────
  Widget _buildDesktopLayout(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(_hPad, 24, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfoSection(isDark),
                _buildPricingSection(isDark),
                _buildThumbnailSection(isDark),
              ],
            ),
          ),
        ),
        // Vertical divider
        Container(width: 1, color: _inputBorder),
        // Right column
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 24, _hPad, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildItinerarySection(isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── MOBILE/TABLET: Single column ─────────────────────────────────────────
  Widget _buildMobileLayout(bool isDark) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(_hPad, 20, _hPad, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(isDark),
              _buildPricingSection(isDark),
              _buildThumbnailSection(isDark),
              _buildItinerarySection(isDark),
            ],
          ),
        ),
        // Floating save button at bottom
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: _buildSaveBar(isDark),
        ),
      ],
    );
  }

  // ── SECTION: Basic info ──────────────────────────────────────────────────
  Widget _buildBasicInfoSection(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      _sectionHeader('Package Details', Icons.card_travel_rounded),

      // Error banner
      if (_errorMessage != null)
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _error.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _error.withOpacity(0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.error_outline, color: _error, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(_errorMessage!,
              style: GoogleFonts.poppins(
                  color: _error, fontSize: 13))),
          ]),
        ),

      // Package name
      TextFormField(
        controller: _nameCtrl,
        textCapitalization: TextCapitalization.words,
        decoration: _fieldDecoration(
          'Package Name *',
          icon: Icons.label_rounded,
          hint: 'e.g. Manali Snow Adventure',
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Package name is required';
          if (v.trim().length < 3) return 'Minimum 3 characters';
          return null;
        },
      ),
      const SizedBox(height: 14),

      // Description
      TextFormField(
        controller: _descCtrl,
        maxLines:   4,
        decoration: _fieldDecoration(
          'Description *',
          hint: 'Describe what makes this package special...',
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Description is required';
          if (v.trim().length < 20) return 'At least 20 characters required';
          return null;
        },
      ),
      const SizedBox(height: 14),

      // Category dropdown
      DropdownButtonFormField<CategoryItem>(
        value: _selectedCategory,
        decoration: _fieldDecoration(
            'Category *', icon: Icons.category_rounded),
        hint: Text('Select category',
            style: GoogleFonts.poppins(fontSize: 13, color: _textSub)),
        items: _categories.map((c) => DropdownMenuItem(
          value: c,
          child: Text(c.categoryname,
              style: GoogleFonts.poppins(fontSize: 13)),
        )).toList(),
        onChanged: (v) => setState(() => _selectedCategory = v),
        validator: (v) =>
            v == null ? 'Please select a category' : null,
        isExpanded: true,
        borderRadius: BorderRadius.circular(12),
      ),
      const SizedBox(height: 14),

      // City dropdown with add button
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DropdownButtonFormField<CityItem>(
              value: _selectedCity,
              decoration: _fieldDecoration(
                  'Destination City *', icon: Icons.location_on_rounded),
              hint: Text('Select city',
                  style: GoogleFonts.poppins(fontSize: 13, color: _textSub)),
              items: _cities.map((c) => DropdownMenuItem(
                value: c,
                child: Text(c.cityname,
                    style: GoogleFonts.poppins(fontSize: 13)),
              )).toList(),
              onChanged: (v) => setState(() => _selectedCity = v),
              validator: (v) =>
                  v == null ? 'Please select a destination city' : null,
              isExpanded: true,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 52, // Match text field height
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.add_location_alt_rounded, color: _primary),
              tooltip: 'Add new city',
              onPressed: () => _showAddCityDialog(isDark),
            ),
          ),
        ],
      ),
    ]);
  }

  // ── SECTION: Pricing & duration ──────────────────────────────────────────
  Widget _buildPricingSection(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      _sectionHeader('Pricing & Duration', Icons.tune_rounded),

      // Days + Nights row
      Row(children: [
        Expanded(
          child: TextFormField(
            controller: _daysCtrl,
            keyboardType: TextInputType.number,
            onChanged: _onDaysChanged,
            decoration: _fieldDecoration(
              'Duration (Days) *',
              icon: Icons.wb_sunny_rounded,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              final n = int.tryParse(v);
              if (n == null || n < 1) return 'Min 1 day';
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _nightsCtrl,
            keyboardType: TextInputType.number,
            decoration: _fieldDecoration(
              'Nights *',
              icon: Icons.nights_stay_rounded,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              final n = int.tryParse(v);
              if (n == null || n < 0) return 'Min 0';
              return null;
            },
          ),
        ),
      ]),
      const SizedBox(height: 14),

      // Price + Max persons row
      Row(children: [
        Expanded(
          child: TextFormField(
            controller: _priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _fieldDecoration(
              'Price per Person (₹) *',
              icon: Icons.currency_rupee_rounded,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              final n = double.tryParse(v);
              if (n == null || n <= 0) return 'Must be > 0';
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _maxPersonsCtrl,
            keyboardType: TextInputType.number,
            decoration: _fieldDecoration(
              'Max Persons *',
              icon: Icons.group_rounded,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              final n = int.tryParse(v);
              if (n == null || n < 1) return 'Min 1';
              return null;
            },
          ),
        ),
      ]),
    ]);
  }

  // ── SECTION: Images ────────────────────────────────────────────────
  Widget _buildThumbnailSection(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('Package Images (Max 5)', Icons.image_rounded),
      const SizedBox(height: 16),
      if (_selectedImages.isNotEmpty) ...[
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[200],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FutureBuilder<List<int>>(
                      future: _selectedImages[index].readAsBytes().then((value) => value.toList()),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Image.memory(
                            Uint8List.fromList(snapshot.data!),
                            fit: BoxFit.cover,
                          );
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 20,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 16, color: Colors.red),
                      ),
                    ),
                  ),
                  if (index == 0)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(150),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Primary', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white)),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
      if (_selectedImages.length < 5)
        OutlinedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text('Add Images', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

      // Desktop: show save bar inside left column
      if (_isDesktop) ...[
        const SizedBox(height: 24),
        _buildSaveBar(isDark)
      ],
    ]);
  }

  // ── SECTION: Itinerary builder ────────────────────────────────────────────
  Widget _buildItinerarySection(bool isDark) {
    final days = int.tryParse(_daysCtrl.text) ?? 0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('Day-wise Itinerary', Icons.map_rounded),

      if (days == 0)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _primary.withOpacity(0.15)),
          ),
          child: Row(children: [
            Icon(Icons.info_outline_rounded,
                color: _primary.withOpacity(0.7), size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'Enter the number of days above to build the day-wise itinerary.',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: _textSub, height: 1.5),
            )),
          ]),
        )
      else
        Column(
          children: List.generate(
            _itinerary.length,
            (i) => _buildItineraryDayCard(i),
          ),
        ),
    ]);
  }

  // ── Save bar (bottom sticky button) ──────────────────────────────────────
  Widget _buildSaveBar(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        _hPad,
        12,
        _hPad,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF142035) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(children: [
        // Cancel
        Expanded(
          child: OutlinedButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 50),
              side: BorderSide(color: _primary.withOpacity(0.4)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Cancel',
              style: GoogleFonts.poppins(
                  color: _primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14)),
          ),
        ),
        const SizedBox(width: 12),
        // Save
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _saving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      widget.isEdit ? 'Update Package' : 'Save Package',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ]),
          ),
        ),
      ]),
    );
  }
}

typedef _InputDecorationBuilder = InputDecoration Function(String label, {IconData? icon, String? hint, Widget? suffix});

class _ItineraryDayCard extends StatefulWidget {
  final ItineraryDayItem day;
  final Color color;
  final bool isFirst;
  final _InputDecorationBuilder fieldDecorationBuilder;

  const _ItineraryDayCard({
    super.key,
    required this.day,
    required this.color,
    required this.isFirst,
    required this.fieldDecorationBuilder,
  });

  @override
  State<_ItineraryDayCard> createState() => _ItineraryDayCardState();
}

class _ItineraryDayCardState extends State<_ItineraryDayCard> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.day.title);
    _descCtrl = TextEditingController(text: widget.day.description);
  }

  @override
  void didUpdateWidget(covariant _ItineraryDayCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.day.dayno != widget.day.dayno) {
       _titleCtrl.text = widget.day.title;
       _descCtrl.text = widget.day.description;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: widget.color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: widget.isFirst,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
          child: Center(
            child: Text(
              '${widget.day.dayno}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Text(
          widget.day.title.isEmpty ? 'Day ${widget.day.dayno} — Add title' : widget.day.title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: widget.day.title.isEmpty ? const Color(0xFF64748B) : const Color(0xFF1E293B),
          ),
        ),
        children: [
          TextFormField(
            controller: _titleCtrl,
            onChanged: (v) {
              setState(() => widget.day.title = v);
            },
            decoration: widget.fieldDecorationBuilder(
              'Day ${widget.day.dayno} Title *',
              icon: Icons.flag_rounded,
              hint: 'e.g. Arrival & Sightseeing in Manali',
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty)
                    ? 'Title is required for Day ${widget.day.dayno}' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _descCtrl,
            onChanged: (v) => widget.day.description = v,
            maxLines: 3,
            decoration: widget.fieldDecorationBuilder(
              'Day ${widget.day.dayno} Description',
              hint: 'Activities, meals, stays for this day...',
            ),
          ),
        ],
      ),
    );
  }
}
