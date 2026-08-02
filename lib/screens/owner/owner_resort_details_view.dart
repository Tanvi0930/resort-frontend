import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_resort_screen.dart';

class OwnerResortDetailsView extends StatefulWidget {
  final List<Map<String, dynamic>> resorts;
  final List<Map<String, dynamic>> locations;
  final bool isAdmin;
  final ValueChanged<Map<String, dynamic>> onResortAdded;
  final Function(int, Map<String, dynamic>) onResortUpdated;
  final ValueChanged<int> onResortDeleted;

  const OwnerResortDetailsView({
    super.key,
    required this.resorts,
    required this.locations,
    this.isAdmin = false,
    required this.onResortAdded,
    required this.onResortUpdated,
    required this.onResortDeleted,
  });

  @override
  State<OwnerResortDetailsView> createState() => _OwnerResortDetailsViewState();
}

class _OwnerResortDetailsViewState extends State<OwnerResortDetailsView> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> get _filteredResorts {
    if (_searchQuery.isEmpty) return widget.resorts;
    return widget.resorts.where((r) {
      final name = (r['name'] ?? '').toString().toLowerCase();
      final location = (r['location'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || location.contains(query);
    }).toList();
  }

  Future<void> _showResortFormDialog({int? index, Map<String, dynamic>? resort}) async {
    final isEditing = index != null && resort != null;
    
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => AddResortScreen(
          locations: widget.locations,
          resortToEdit: resort,
        ),
      ),
    );

    if (result != null) {
      if (isEditing) {
        widget.onResortUpdated(index, result);
      } else {
        widget.onResortAdded(result);
      }
    }
  }



  void _showDeleteConfirmDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Resort',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2D27))),
        content: const Text(
            'Are you sure you want to delete this resort? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              widget.onResortDeleted(index);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredResorts;
    final isMobile = MediaQuery.of(context).size.width < 600;

    final searchBar = Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: const InputDecoration(
          hintText: 'Search resorts by name or location...',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
          prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );

    final addButton = widget.isAdmin
        ? ElevatedButton.icon(
            onPressed: () => _showResortFormDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Resort Details'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F4C43),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          )
        : const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    searchBar,
                    if (widget.isAdmin) const SizedBox(height: 12),
                    if (widget.isAdmin) addButton,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: searchBar),
                    if (widget.isAdmin) const SizedBox(width: 16),
                    if (widget.isAdmin) addButton,
                  ],
                ),
          const SizedBox(height: 20),

          const SizedBox(height: 12),

          // Resort Cards Grid
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(60),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.villa_outlined, size: 60, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('No resorts found',
                        style: TextStyle(
                            fontSize: 16, color: Color(0xFF1E2D27),
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(widget.isAdmin ? 'Add your first resort to get started' : 'You currently have no resort details to display.',
                        style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 900;
                
                if (!isDesktop) {
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, i) {
                      final resort = filtered[i];
                      final originalIndex = widget.resorts.indexOf(resort);
                      return _buildResortCard(resort, originalIndex);
                    },
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final resort = filtered[i];
                    final originalIndex = widget.resorts.indexOf(resort);
                    return _buildResortCard(resort, originalIndex);
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String label, String value, IconData icon, Color color, Color bg, {bool isMobile = false}) {
    return Container(
      width: isMobile ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isMobile
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E2D27))),
                    Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: bg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 20, color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1E2D27))),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black54)),
              ],
            ),
    );
  }

  Widget _buildResortCard(Map<String, dynamic> resort, int index) {
    final rating = (resort['rating'] as num? ?? 0).toDouble();
    final rooms = resort['rooms'] ?? 0;
    final lockerNo = resort['lockerNo'] ?? 0;
    final price = (resort['price'] as num? ?? 0).toInt();
    
    List<String> foodOptions = [];
    if (resort['foodDetails'] != null) {
      if (resort['foodDetails']['veg'] == true) foodOptions.add('Veg');
      if (resort['foodDetails']['nonVeg'] == true) foodOptions.add('Non-Veg');
      if (resort['foodDetails']['breakfast'] == true) foodOptions.add('Breakfast');
      if (resort['foodDetails']['breaksnacks'] == true) foodOptions.add('Snacks');
    }
    String foodStr = foodOptions.isEmpty ? 'None' : foodOptions.join(', ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image & Overlays
            Stack(
              children: [
                Image.network(
                  resort['imageUrl'] ?? 'https://images.unsplash.com/photo-1540541338287-41700207dee6?q=80&w=2070',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                ),
                // Top-Left Rating overlay
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Top-Right Status overlay
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (resort['status'] ?? 'Approved') == 'Approved'
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      resort['status'] ?? 'Approved',
                      style: TextStyle(
                        color: (resort['status'] ?? 'Approved') == 'Approved'
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFC62828),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    resort['name'] ?? 'Unnamed Resort',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E2D27),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Location Line
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          resort['location'] ?? 'Location',
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Amenities/Specs Tags Row
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildCompactTag(Icons.bed_outlined, '$rooms Rooms', Colors.blue.shade700, Colors.blue.shade50),
                      _buildCompactTag(Icons.lock_outline, '$lockerNo Lockers', Colors.orange.shade700, Colors.orange.shade50),
                      if ((resort['serviceOption'] ?? '').isNotEmpty)
                        _buildCompactTag(Icons.room_service_outlined, resort['serviceOption'], Colors.teal.shade700, Colors.teal.shade50),
                      _buildCompactTag(Icons.restaurant_menu, foodStr, Colors.purple.shade700, Colors.purple.shade50),
                    ],
                  ),

                  if ((resort['contactNo'] ?? '').isNotEmpty || (resort['email'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((resort['contactNo'] ?? '').isNotEmpty)
                          _buildContactRow(Icons.phone_outlined, resort['contactNo']),
                        if ((resort['email'] ?? '').isNotEmpty)
                          const SizedBox(height: 4),
                        if ((resort['email'] ?? '').isNotEmpty)
                          _buildContactRow(Icons.email_outlined, resort['email']),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFEEEEEE), height: 1),
                  const SizedBox(height: 12),

                  // Bottom Pricing & Edit/Delete Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '₹$price',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF1E2D27),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '/ pax',
                                style: GoogleFonts.inter(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                            onPressed: () => _showResortFormDialog(index: index, resort: resort),
                            tooltip: 'Edit Resort',
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                            onPressed: () => _showDeleteConfirmDialog(index),
                            tooltip: 'Delete Resort',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactTag(IconData icon, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 140,
      color: const Color(0xFFF0F4F2),
      child: const Center(
        child: Icon(Icons.villa_outlined, size: 40, color: Color(0xFF0F4C43)),
      ),
    );
  }
}
