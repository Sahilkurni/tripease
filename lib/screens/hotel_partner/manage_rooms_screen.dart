import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/hotel_partner_service.dart';

class ManageRoomsScreen extends StatefulWidget {
  final int hotelid;
  final String hotelname;
  final int partnerid;
  final int userid;

  const ManageRoomsScreen({
    super.key,
    required this.hotelid,
    required this.hotelname,
    required this.partnerid,
    required this.userid,
  });

  @override
  State<ManageRoomsScreen> createState() => _ManageRoomsScreenState();
}

class _ManageRoomsScreenState extends State<ManageRoomsScreen> {
  bool _isLoading = true;
  List<RoomItem> _rooms = [];
  List<RoomTypeItem> _roomTypes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final types = await HotelPartnerService.getRoomTypes();
      final rooms = await HotelPartnerService.getRooms(widget.hotelid, widget.partnerid);
      if (mounted) {
        setState(() {
          _roomTypes = types;
          _rooms = rooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load rooms: $e')));
      }
    }
  }

  Future<void> _deleteRoom(int roomid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Room'),
        content: const Text('Are you sure you want to delete this room type? This will also remove its inventory.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await HotelPartnerService.deleteRoom(roomid, widget.partnerid, widget.userid);
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting room: $e')));
    }
  }

  void _showAddEditSheet({RoomItem? room}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RoomBottomSheet(
        room: room,
        roomTypes: _roomTypes,
        hotelid: widget.hotelid,
        partnerid: widget.partnerid,
        userid: widget.userid,
        onSaved: () {
          Navigator.pop(ctx);
          _loadData();
        },
      ),
    );
  }

  Widget _buildStat(String title, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(title, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalRoomsSum = _rooms.fold(0, (sum, r) => sum + r.totalrooms);
    double avgPrice = _rooms.isEmpty ? 0 : _rooms.fold(0.0, (sum, r) => sum + r.price) / _rooms.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Rooms — ${widget.hotelname}', style: GoogleFonts.poppins()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.blue, Colors.blueAccent]),
                  ),
                  child: Row(
                    children: [
                      _buildStat('Total Room Types', _rooms.length.toString()),
                      _buildStat('Total Rooms', totalRoomsSum.toString()),
                      _buildStat('Avg Price', '₹${avgPrice.toStringAsFixed(0)}'),
                    ],
                  ),
                ),
                Expanded(
                  child: _rooms.isEmpty
                      ? const Center(child: Text('No rooms added yet.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _rooms.length,
                          itemBuilder: (ctx, i) {
                            final r = _rooms[i];
                            final color = Colors.primaries[r.roomtypeid % Colors.primaries.length];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              clipBehavior: Clip.antiAlias,
                              child: IntrinsicHeight(
                                child: Row(
                                  children: [
                                    Container(width: 6, color: color),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(child: Text(r.roomname, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold))),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                                                  child: Text(r.roomtype, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                const Icon(Icons.people, size: 16, color: Colors.grey),
                                                const SizedBox(width: 8),
                                                Text('Max ${r.capacity} guests', style: const TextStyle(color: Colors.grey)),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.meeting_room, size: 16, color: Colors.grey),
                                                const SizedBox(width: 8),
                                                Text('${r.totalrooms} rooms available', style: const TextStyle(color: Colors.grey)),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Text('₹${r.price}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                                                const Spacer(),
                                                Text('+ ₹${r.extraBedPrice} extra bed', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showAddEditSheet(room: r)),
                                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteRoom(r.roomid)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEditSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _RoomBottomSheet extends StatefulWidget {
  final RoomItem? room;
  final List<RoomTypeItem> roomTypes;
  final int hotelid;
  final int partnerid;
  final int userid;
  final VoidCallback onSaved;

  const _RoomBottomSheet({
    this.room,
    required this.roomTypes,
    required this.hotelid,
    required this.partnerid,
    required this.userid,
    required this.onSaved,
  });

  @override
  State<_RoomBottomSheet> createState() => _RoomBottomSheetState();
}

class _RoomBottomSheetState extends State<_RoomBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedTypeId;
  final _nameCtrl = TextEditingController();
  final _capCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _extraCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      _selectedTypeId = widget.room!.roomtypeid;
      _nameCtrl.text = widget.room!.roomname;
      _capCtrl.text = widget.room!.capacity.toString();
      _totalCtrl.text = widget.room!.totalrooms.toString();
      _priceCtrl.text = widget.room!.price.toString();
      _extraCtrl.text = widget.room!.extraBedPrice.toString();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a room type')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await HotelPartnerService.saveRoom({
        'roomid': widget.room?.roomid,
        'hotelid': widget.hotelid,
        'partnerid': widget.partnerid,
        'roomtypeid': _selectedTypeId,
        'roomname': _nameCtrl.text.trim(),
        'capacity': int.parse(_capCtrl.text.trim()),
        'totalrooms': int.parse(_totalCtrl.text.trim()),
        'price': double.parse(_priceCtrl.text.trim()),
        'extra_bed_price': _extraCtrl.text.trim().isEmpty ? 0 : double.parse(_extraCtrl.text.trim()),
        'uid': widget.userid,
      });
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: scrollController,
            children: [
              Text(widget.room == null ? 'Add Room' : 'Edit Room', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              DropdownButtonFormField<int>(
                value: _selectedTypeId,
                decoration: const InputDecoration(labelText: 'Room Type *', border: OutlineInputBorder()),
                items: widget.roomTypes.map((t) => DropdownMenuItem(value: t.roomtypeid, child: Text(t.typename))).toList(),
                onChanged: (val) => setState(() => _selectedTypeId = val),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Room Name *', border: OutlineInputBorder()),
                validator: (val) => (val == null || val.trim().length < 3) ? 'Min 3 chars' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _capCtrl,
                      decoration: const InputDecoration(labelText: 'Capacity *', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (val) => (val == null || int.tryParse(val) == null || int.parse(val) <= 0) ? 'Invalid' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _totalCtrl,
                      decoration: const InputDecoration(labelText: 'Total Rooms *', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (val) => (val == null || int.tryParse(val) == null || int.parse(val) <= 0) ? 'Invalid' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(labelText: 'Price per night (₹) *', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (val) => (val == null || double.tryParse(val) == null || double.parse(val) <= 0) ? 'Invalid' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _extraCtrl,
                      decoration: const InputDecoration(labelText: 'Extra Bed (₹)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (val) => (val != null && val.isNotEmpty && double.tryParse(val) == null) ? 'Invalid' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Room'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
