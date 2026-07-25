import 'package:flutter/material.dart';

class AdminLocationsView extends StatefulWidget {
  final List<Map<String, dynamic>> locations;
  final ValueChanged<Map<String, dynamic>> onLocationAdded;
  final Function(int, Map<String, dynamic>) onLocationUpdated;
  final ValueChanged<int> onLocationDeleted;

  const AdminLocationsView({
    super.key,
    required this.locations,
    required this.onLocationAdded,
    required this.onLocationUpdated,
    required this.onLocationDeleted,
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
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEditing ? 'Edit Location Details' : 'Add New Location',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A2B)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: stateController,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Pin Code',
                        prefixIcon: Icon(Icons.pin_drop_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
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
                      final originalIndex = widget.locations.indexOf(loc);
                      widget.onLocationUpdated(originalIndex, data);
                    } else {
                      widget.onLocationAdded(data);
                    }

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3E7C59),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    isEditing ? 'Save Changes' : 'Add Location',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmDialog(Map<String, dynamic> loc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently delete location ${loc['city']}, ${loc['state']}? All listings associated with this region may be affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final originalIndex = widget.locations.indexOf(loc);
              widget.onLocationDeleted(originalIndex);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Text(
                    'Locations Management',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A2B),
                    ),
                  ),
                  const Spacer(),
                  // Search Box
                  Container(
                    width: 220,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F5F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search city/state/pin...',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                        prefixIcon: Icon(Icons.search, size: 16, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Add Button
                  ElevatedButton.icon(
                    onPressed: () => _showLocationFormDialog(),
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text('Add Location', style: TextStyle(fontSize: 12, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3E7C59),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Expanded(
                child: _filteredLocations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text('No locations found.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )
                    : isDesktop
                        ? _buildLocationsTable()
                        : _buildLocationsCardGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- DESKTOP DATA TABLE ---
  Widget _buildLocationsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF7F9F6)),
          horizontalMargin: 12,
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('City', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A2B)))),
            DataColumn(label: Text('State', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A2B)))),
            DataColumn(label: Text('Pin Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A2B)))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A2B)))),
          ],
          rows: _filteredLocations.map((l) {
            return DataRow(
              cells: [
                DataCell(Text(l['city'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                DataCell(Text(l['state'] ?? '', style: const TextStyle(fontSize: 13))),
                DataCell(Text(l['pin'] ?? '', style: const TextStyle(fontSize: 13))),
                DataCell(Row(
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
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- MOBILE GRID / WRAP CARDS ---
  Widget _buildLocationsCardGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 2.2,
      ),
      itemCount: _filteredLocations.length,
      itemBuilder: (context, index) {
        final l = _filteredLocations[index];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.01),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F3EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF3E7C59),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l['city'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A2B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l['state'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pin: ${l['pin'] ?? ''}',
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
          ),
        );
      },
    );
  }
}
