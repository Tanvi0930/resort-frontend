import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminLocationsView extends StatefulWidget {
  final List<Map<String, dynamic>> locations;
  final ValueChanged<Map<String, dynamic>> onLocationAdded;
  final Function(int, Map<String, dynamic>) onLocationUpdated;
  final ValueChanged<int> onLocationDeleted;
  final VoidCallback? onBack;

  const AdminLocationsView({
    super.key,
    required this.locations,
    required this.onLocationAdded,
    required this.onLocationUpdated,
    required this.onLocationDeleted,
    this.onBack,
  });

  @override
  State<AdminLocationsView> createState() => _AdminLocationsViewState();
}

class _AdminLocationsViewState extends State<AdminLocationsView> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> get _filteredLocations {
    if (_searchQuery.isEmpty) return widget.locations;
    return widget.locations.where((l) {
      final city = (l['city'] ?? '').toString().toLowerCase();
      final state = (l['state'] ?? '').toString().toLowerCase();
      final pin = (l['pin'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return city.contains(query) || state.contains(query) || pin.contains(query);
    }).toList();
  }

  void _showLocationFormDialog({int? index, Map<String, dynamic>? loc}) {
    final isEditing = index != null && loc != null;
    final cityController = TextEditingController(text: isEditing ? loc['city'] : '');
    final stateController = TextEditingController(text: isEditing ? loc['state'] : '');
    final pinController = TextEditingController(text: isEditing ? loc['pin'] : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEditing ? 'Edit Location' : 'Add Location',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1E2D27)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogField(cityController, 'City', Icons.location_city_outlined),
                const SizedBox(height: 12),
                _buildDialogField(stateController, 'State', Icons.map_outlined),
                const SizedBox(height: 12),
                _buildDialogField(pinController, 'Pin Code', Icons.pin_drop_outlined, isNumber: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final city = cityController.text.trim();
                final state = stateController.text.trim();
                final pin = pinController.text.trim();

                if (city.isEmpty || state.isEmpty || pin.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill out all fields')),
                  );
                  return;
                }

                final data = {
                  'id': isEditing ? loc['id'] : 'L${widget.locations.length + 1}',
                  'city': city,
                  'state': state,
                  'pin': pin,
                };

                if (isEditing) {
                  widget.onLocationUpdated(index, data);
                } else {
                  widget.onLocationAdded(data);
                }

                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F4C43),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                isEditing ? 'Save' : 'Add',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(Map<String, dynamic> loc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Location', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1E2D27))),
        content: Text('Are you sure you want to delete location ${loc['city']}, ${loc['state']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final originalIndex = widget.locations.indexOf(loc);
              widget.onLocationDeleted(originalIndex);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                if (widget.onBack != null) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF1E2D27)),
                    onPressed: widget.onBack,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  'Locations Management',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E2D27),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search input field
            Container(
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search city, state, or pin code...',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            // Locations list
            Expanded(
              child: _filteredLocations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off_outlined, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text('No locations found.', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    )
                  : isDesktop
                      ? _buildLocationsTable(_filteredLocations)
                      : _buildLocationsCardGrid(_filteredLocations),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLocationFormDialog(),
        backgroundColor: const Color(0xFF0F4C43),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildLocationsTable(List<Map<String, dynamic>> list) {
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(color: Color(0xFFEEEEEE), height: 1),
      itemBuilder: (context, idx) {
        final l = list[idx];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF0F4C43), size: 18),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  l['city'] ?? '',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1E2D27)),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  l['state'] ?? '',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  l['pin'] ?? '',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                    onPressed: () => _showLocationFormDialog(index: widget.locations.indexOf(l), loc: l),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    onPressed: () => _showDeleteConfirmDialog(l),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationsCardGrid(List<Map<String, dynamic>> list) {
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final l = list[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on, color: Color(0xFF0F4C43), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l['city'] ?? '',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1E2D27)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l['state'] ?? ''} • Pin ${l['pin'] ?? ''}',
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
                    onPressed: () => _showLocationFormDialog(index: widget.locations.indexOf(l), loc: l),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                    onPressed: () => _showDeleteConfirmDialog(l),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDialogField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E2D27)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500),
        prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0F4C43), width: 1.5),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      ),
    );
  }
}
