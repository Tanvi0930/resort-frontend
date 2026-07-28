import 'package:flutter/material.dart';

class OwnerResortDetailsView extends StatefulWidget {
  final List<Map<String, dynamic>> resorts;
  final ValueChanged<Map<String, dynamic>> onResortAdded;
  final Function(int, Map<String, dynamic>) onResortUpdated;
  final ValueChanged<int> onResortDeleted;

  const OwnerResortDetailsView({
    super.key,
    required this.resorts,
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

  void _showResortFormDialog({int? index, Map<String, dynamic>? resort}) {
    final isEditing = index != null && resort != null;
    final nameController = TextEditingController(text: isEditing ? resort['name'] : '');
    final contactController = TextEditingController(text: isEditing ? resort['contactNo'] : '');
    final emailController = TextEditingController(text: isEditing ? resort['email'] : '');
    
    String initialCity = '';
    String initialState = '';
    if (isEditing && resort['location'] != null) {
      final parts = resort['location'].toString().split(', ');
      if (parts.isNotEmpty) initialCity = parts[0];
      if (parts.length >= 2) initialState = parts[1];
    }
    
    final cityController = TextEditingController(text: initialCity);
    final stateController = TextEditingController(text: initialState);

    final roomsController = TextEditingController(text: isEditing ? '${resort['rooms'] ?? ''}' : '');
    final lockerController = TextEditingController(text: isEditing ? '${resort['lockerNo'] ?? ''}' : '');
    final priceController = TextEditingController(text: isEditing ? '${resort['price'] ?? ''}' : '');
    final serviceController = TextEditingController(text: isEditing ? resort['serviceOption'] : '');
    final ratingController = TextEditingController(text: isEditing ? '${resort['rating'] ?? ''}' : '');
    final descriptionController = TextEditingController(text: isEditing ? resort['description'] ?? '' : '');

    bool isVeg = isEditing && resort['foodDetails'] != null ? resort['foodDetails']['veg'] ?? false : false;
    bool isNonVeg = isEditing && resort['foodDetails'] != null ? resort['foodDetails']['nonVeg'] ?? false : false;
    bool isBreakfast = isEditing && resort['foodDetails'] != null ? resort['foodDetails']['breakfast'] ?? false : false;
    bool isBreaksnacks = isEditing && resort['foodDetails'] != null ? resort['foodDetails']['breaksnacks'] ?? false : false;

    // Parse categories from comma-separated string
    final catStr = (isEditing && resort['category'] != null) ? resort['category'].toString().toLowerCase() : '';
    bool isFamily = catStr.contains('family');
    bool isGroup = catStr.contains('group');
    bool isSchoolTrip = catStr.contains('school trip');
    bool isCorporate = catStr.contains('corporate');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEditing ? 'Edit Resort Details' : 'Add New Resort',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A2B)),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFormField(nameController, 'Resort Name', Icons.villa_outlined),
                      const SizedBox(height: 12),
                      _buildFormField(contactController, 'Contact No', Icons.phone_outlined, isNumber: true),
                      const SizedBox(height: 12),
                      _buildFormField(emailController, 'Email', Icons.email_outlined),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormField(stateController, 'State', Icons.map_outlined),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFormField(cityController, 'City', Icons.location_city_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormField(roomsController, 'Rooms No Available', Icons.bed_outlined, isNumber: true),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFormField(lockerController, 'Locker No Available', Icons.lock_outline, isNumber: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormField(priceController, 'Per Person Price (₹)', Icons.currency_rupee, isNumber: true),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFormField(ratingController, 'Rating (0-5)', Icons.star_border, isNumber: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildFormField(serviceController, 'Service Option', Icons.room_service_outlined),
                      const SizedBox(height: 12),
                      
                      // Categories Section
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Resort Categories',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A2B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _buildCheckbox('Family', isFamily, (val) => setDialogState(() => isFamily = val!)),
                          _buildCheckbox('Groups', isGroup, (val) => setDialogState(() => isGroup = val!)),
                          _buildCheckbox('School Trip', isSchoolTrip, (val) => setDialogState(() => isSchoolTrip = val!)),
                          _buildCheckbox('Corporate', isCorporate, (val) => setDialogState(() => isCorporate = val!)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Food Details Section
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Food Details',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A2B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _buildCheckbox('Veg', isVeg, (val) => setDialogState(() => isVeg = val!)),
                          _buildCheckbox('Non-Veg', isNonVeg, (val) => setDialogState(() => isNonVeg = val!)),
                          _buildCheckbox('Breakfast', isBreakfast, (val) => setDialogState(() => isBreakfast = val!)),
                          _buildCheckbox('Breaksnacks', isBreaksnacks, (val) => setDialogState(() => isBreaksnacks = val!)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          labelStyle: const TextStyle(
                              fontSize: 13, color: Colors.grey),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 40),
                            child: Icon(Icons.description_outlined,
                                size: 18, color: Colors.grey),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Color(0xFF3E7C59), width: 1.5),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF7F9F6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3E7C59),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final newResort = {
                      'id': isEditing
                          ? resort['id']
                          : 'R${DateTime.now().millisecondsSinceEpoch}',
                      'name': nameController.text.trim(),
                      'contactNo': contactController.text.trim(),
                      'email': emailController.text.trim(),
                      'location': [cityController.text.trim(), stateController.text.trim()].where((e) => e.isNotEmpty).join(', '),
                      'rooms': int.tryParse(roomsController.text.trim()) ?? 0,
                      'lockerNo': int.tryParse(lockerController.text.trim()) ?? 0,
                      'price': double.tryParse(priceController.text.trim()) ?? 0.0,
                      'serviceOption': serviceController.text.trim(),
                      'rating': double.tryParse(ratingController.text.trim()) ?? 0.0,
                      'foodDetails': {
                        'veg': isVeg,
                        'nonVeg': isNonVeg,
                        'breakfast': isBreakfast,
                        'breaksnacks': isBreaksnacks,
                      },
                      'category': [
                        if (isFamily) 'Family',
                        if (isGroup) 'Groups',
                        if (isSchoolTrip) 'School Trip',
                        if (isCorporate) 'Corporate',
                      ].join(', '),
                      'description': descriptionController.text.trim(),
                    };
                    Navigator.pop(context);
                    if (isEditing) {
                      widget.onResortUpdated(index, newResort);
                    } else {
                      widget.onResortAdded(newResort);
                    }
                  },
                  child: Text(isEditing ? 'Save Details' : 'Add Resort Details'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCheckbox(String title, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF3E7C59),
        ),
        Text(title, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _buildFormField(
      TextEditingController controller, String label, IconData icon,
      {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType:
          isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        prefixIcon: Icon(icon, size: 18, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF3E7C59), width: 1.5),
        ),
        filled: true,
        fillColor: const Color(0xFFF7F9F6),
      ),
    );
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
                color: Color(0xFF1E3A2B))),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        setState(() => _searchQuery = val),
                    decoration: const InputDecoration(
                      hintText: 'Search resorts by name or location...',
                      hintStyle:
                          TextStyle(fontSize: 13, color: Colors.grey),
                      prefixIcon: Icon(Icons.search,
                          size: 18, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showResortFormDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Resort Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3E7C59),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats Summary Row
          Row(
            children: [
              _buildSummaryChip(
                  '${widget.resorts.length} Resorts',
                  Icons.villa_outlined,
                  const Color(0xFF3E7C59),
                  const Color(0xFFE8F3EB)),
              const SizedBox(width: 12),
              _buildSummaryChip(
                  '${widget.resorts.fold(0, (sum, r) => sum + ((r['rooms'] as num?) ?? 0).toInt())} Total Rooms',
                  Icons.bed_outlined,
                  const Color(0xFF5A93E5),
                  const Color(0xFFEBF1FC)),
              const SizedBox(width: 12),
              _buildSummaryChip(
                  '${filtered.length} Shown',
                  Icons.filter_list,
                  const Color(0xFFE5A93C),
                  const Color(0xFFFDF3E3)),
            ],
          ),
          const SizedBox(height: 20),

          // Resort Cards Grid
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(60),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.villa_outlined, size: 60, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No resorts found',
                        style: TextStyle(
                            fontSize: 16, color: Color(0xFF1E3A2B),
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text('Add your first resort to get started',
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final crossCount = constraints.maxWidth > 900 ? 2 : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: crossCount == 2 ? 1.7 : 2.2,
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

  Widget _buildSummaryChip(
      String label, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }

  Widget _buildResortCard(Map<String, dynamic> resort, int index) {
    final rating = (resort['rating'] as num? ?? 0).toDouble();
    final rooms = resort['rooms'] ?? 0;
    final lockerNo = resort['lockerNo'] ?? 0;
    final price = (resort['price'] as num? ?? 0).toInt();
    final imageUrl = resort['imageUrl'] ?? '';
    
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              resort['name'] ?? 'Unnamed Resort',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A2B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '₹$price / person',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3E7C59)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          _buildDetailText(Icons.location_on, resort['location'] ?? ''),
                          if ((resort['contactNo'] ?? '').isNotEmpty) _buildDetailText(Icons.phone, resort['contactNo']),
                          if ((resort['email'] ?? '').isNotEmpty) _buildDetailText(Icons.email, resort['email']),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(resort['category'] ?? 'Category', Icons.category_outlined, const Color(0xFFE5A93C), const Color(0xFFFDF3E3)),
                          _buildInfoChip('$rooms Rooms', Icons.bed_outlined, const Color(0xFF5A93E5), const Color(0xFFEBF1FC)),
                          _buildInfoChip('$lockerNo Lockers', Icons.lock_outline, const Color(0xFFE5A93C), const Color(0xFFFDF3E3)),
                          if ((resort['serviceOption'] ?? '').isNotEmpty)
                            _buildInfoChip(resort['serviceOption'], Icons.room_service_outlined, const Color(0xFF9C6FDE), const Color(0xFFF3EDFB)),
                          _buildInfoChip(foodStr, Icons.restaurant_menu, const Color(0xFF3E7C59), const Color(0xFFE8F3EB)),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Color(0xFFE5A93C)),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A2B)),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF3E7C59)),
                        onPressed: () => _showResortFormDialog(index: index, resort: resort),
                        tooltip: 'Edit',
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFE57373)),
                        onPressed: () => _showDeleteConfirmDialog(index),
                        tooltip: 'Delete',
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 140,
      color: const Color(0xFFE8F3EB),
      child: const Center(
        child: Icon(Icons.villa_outlined, size: 40, color: Color(0xFF3E7C59)),
      ),
    );
  }
}
