import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class AddResortScreen extends StatefulWidget {
  final List<Map<String, dynamic>> locations;
  final Map<String, dynamic>? resortToEdit; // If editing, otherwise null

  const AddResortScreen({
    super.key,
    required this.locations,
    this.resortToEdit,
  });

  @override
  State<AddResortScreen> createState() => _AddResortScreenState();
}

class _AddResortScreenState extends State<AddResortScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _contactController;
  late TextEditingController _emailController;
  late TextEditingController _roomsController;
  late TextEditingController _lockerController;
  late TextEditingController _priceController;
  late TextEditingController _serviceController;
  late TextEditingController _ratingController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  late TextEditingController _videoUrlController;

  String? _selectedState;
  String? _selectedCity;
  
  bool _veg = false;
  bool _nonVeg = false;
  bool _breakfast = false;
  bool _breaksnacks = false;

  bool _categoryFamily = false;
  bool _categoryGroup = false;
  bool _categorySchool = false;
  bool _categoryCorporate = false;

  bool _isSaving = false;



  @override
  void initState() {
    super.initState();
    final isEditing = widget.resortToEdit != null;
    final r = widget.resortToEdit;

    _nameController = TextEditingController(text: isEditing ? r!['name'] : '');
    _contactController = TextEditingController(text: isEditing ? r!['contactNo'] : '');
    _emailController = TextEditingController(text: isEditing ? r!['email'] : '');
    _roomsController = TextEditingController(text: isEditing ? '${r!['rooms'] ?? ''}' : '');
    _lockerController = TextEditingController(text: isEditing ? '${r!['lockerNo'] ?? ''}' : '');
    _priceController = TextEditingController(text: isEditing ? '${r!['price'] ?? ''}' : '');
    _serviceController = TextEditingController(text: isEditing ? r!['serviceOption'] : '');
    _ratingController = TextEditingController(text: isEditing ? '${r!['rating'] ?? ''}' : '4.5');
    _descriptionController = TextEditingController(text: isEditing ? r!['description'] ?? '' : '');
    _imageUrlController = TextEditingController(text: isEditing ? r!['imageUrl'] ?? '' : '');
    _videoUrlController = TextEditingController(text: isEditing ? r!['videoUrl'] ?? '' : '');

    if (isEditing && r!['location'] != null) {
      final parts = r['location'].toString().split(', ');
      if (parts.isNotEmpty) _selectedCity = parts[0];
      if (parts.length >= 2) _selectedState = parts[1];
    }

    if (isEditing && r!['foodDetails'] != null) {
      _veg = r['foodDetails']['veg'] ?? false;
      _nonVeg = r['foodDetails']['nonVeg'] ?? false;
      _breakfast = r['foodDetails']['breakfast'] ?? false;
      _breaksnacks = r['foodDetails']['breaksnacks'] ?? false;
    }

    if (isEditing && r!['category'] != null) {
      final catStr = r['category'].toString().toLowerCase();
      _categoryFamily = catStr.contains('family');
      _categoryGroup = catStr.contains('group');
      _categorySchool = catStr.contains('school trip');
      _categoryCorporate = catStr.contains('corporate');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _roomsController.dispose();
    _lockerController.dispose();
    _priceController.dispose();
    _serviceController.dispose();
    _ratingController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedState == null || _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select state and city location')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final finalImageUrl = _imageUrlController.text.isNotEmpty 
        ? _imageUrlController.text 
        : 'https://images.unsplash.com/photo-1540541338287-41700207dee6?q=80&w=2070';

    // Build category string
    final List<String> cats = [];
    if (_categoryFamily) cats.add('Family');
    if (_categoryGroup) cats.add('Group');
    if (_categorySchool) cats.add('School Trip');
    if (_categoryCorporate) cats.add('Corporate');
    final categoryString = cats.join(', ');

    final resortBody = {
      if (widget.resortToEdit != null) 'id': widget.resortToEdit!['id'],
      'name': _nameController.text.trim(),
      'location': '$_selectedCity, $_selectedState',
      'contactNo': _contactController.text.trim(),
      'email': _emailController.text.trim(),
      'rooms': int.tryParse(_roomsController.text) ?? 0,
      'lockerNo': int.tryParse(_lockerController.text) ?? 0,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'serviceOption': _serviceController.text.trim(),
      'imageUrl': finalImageUrl,
      'videoUrl': _videoUrlController.text.trim(),
      'rating': double.tryParse(_ratingController.text) ?? 4.5,
      'description': _descriptionController.text.trim(),
      'veg': _veg,
      'nonVeg': _nonVeg,
      'breakfast': _breakfast,
      'breaksnacks': _breaksnacks,
      'category': categoryString,
    };

    Navigator.pop(context, resortBody);
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _imageUrlController.text = image.path;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image selected from gallery successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _pickVideoFromGallery() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? video = await picker.pickVideo(
        source: ImageSource.gallery,
      );
      if (video != null) {
        setState(() {
          _videoUrlController.text = video.path;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video selected from gallery successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick video: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableStates = widget.locations
        .map((l) => l['state']?.toString().trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
        ..sort();

    final availableCities = _selectedState == null 
        ? <String>[]
        : widget.locations
            .where((l) => l['state']?.toString().trim() == _selectedState?.trim())
            .map((l) => l['city']?.toString().trim() ?? '')
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
            ..sort();

    final isEditing = widget.resortToEdit != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F4C43),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isEditing ? 'Edit Resort' : 'Add Resort',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F4C43)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Modify Resort Portfolio' : 'Register New Resort Property',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E2D27),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Provide required info, including location, price, and media.',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    // Section: General Details
                    _buildSectionHeader('General Details'),
                    const SizedBox(height: 12),
                    _buildFormField(_nameController, 'Resort Name', Icons.villa_outlined),
                    const SizedBox(height: 12),
                    _buildFormField(_descriptionController, 'Description', Icons.description_outlined, maxLines: 3),
                    
                    const SizedBox(height: 16),
                    _buildSectionHeader('Location'),
                    const SizedBox(height: 12),
                    
                    // State & City Dropdowns
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            hint: 'State',
                            value: _selectedState,
                            items: availableStates,
                            onChanged: (val) {
                              setState(() {
                                _selectedState = val;
                                _selectedCity = null;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            hint: 'City',
                            value: _selectedCity,
                            items: availableCities,
                            onChanged: (val) {
                              setState(() => _selectedCity = val);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    _buildSectionHeader('Specifications & Price'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildFormField(_priceController, 'Price (₹)', Icons.currency_rupee, isNumber: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildFormField(_roomsController, 'Total Rooms', Icons.bed_outlined, isNumber: true)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildFormField(_lockerController, 'Lockers Count', Icons.lock_outline, isNumber: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildFormField(_ratingController, 'Rating (1-5)', Icons.star_outline, isNumber: true)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildFormField(_serviceController, 'Service Option (e.g. Self Service)', Icons.room_service_outlined),

                    const SizedBox(height: 16),
                    _buildSectionHeader('Contact Information'),
                    const SizedBox(height: 12),
                    _buildFormField(_contactController, 'Contact Number', Icons.phone_outlined, isNumber: true),
                    const SizedBox(height: 12),
                    _buildFormField(_emailController, 'Email Address', Icons.email_outlined),

                    const SizedBox(height: 16),
                    _buildSectionHeader('Food Details'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 16,
                      children: [
                        _buildCheckbox('Veg Food Available', _veg, (val) => setState(() => _veg = val ?? false)),
                        _buildCheckbox('Non-Veg Available', _nonVeg, (val) => setState(() => _nonVeg = val ?? false)),
                        _buildCheckbox('Breakfast Included', _breakfast, (val) => setState(() => _breakfast = val ?? false)),
                        _buildCheckbox('Snacks Available', _breaksnacks, (val) => setState(() => _breaksnacks = val ?? false)),
                      ],
                    ),

                    const SizedBox(height: 16),
                    _buildSectionHeader('Categories'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 16,
                      children: [
                        _buildCheckbox('Family Suitable', _categoryFamily, (val) => setState(() => _categoryFamily = val ?? false)),
                        _buildCheckbox('Group/Friends', _categoryGroup, (val) => setState(() => _categoryGroup = val ?? false)),
                        _buildCheckbox('School Trips', _categorySchool, (val) => setState(() => _categorySchool = val ?? false)),
                        _buildCheckbox('Corporate events', _categoryCorporate, (val) => setState(() => _categoryCorporate = val ?? false)),
                      ],
                    ),                    // Section: Media Upload
                    const SizedBox(height: 16),
                    _buildSectionHeader('Resort Cover Image'),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickImageFromGallery,
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _imageUrlController.text.isEmpty ? Colors.grey.shade300 : const Color(0xFF0F4C43),
                            width: _imageUrlController.text.isEmpty ? 1.5 : 2.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _imageUrlController.text.isEmpty
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Choose Cover Image from Gallery',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Formats supported: JPG, PNG',
                                      style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade400),
                                    ),
                                  ],
                                )
                              : Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    kIsWeb || _imageUrlController.text.startsWith('http') || _imageUrlController.text.startsWith('blob:')
                                        ? Image.network(
                                            _imageUrlController.text,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.file(
                                            File(_imageUrlController.text),
                                            fit: BoxFit.cover,
                                          ),
                                    Container(
                                      color: Colors.black.withOpacity(0.3),
                                      alignment: Alignment.center,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.refresh, size: 14, color: Colors.white),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Change Cover Image',
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    _buildSectionHeader('Resort Walkthrough Video'),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickVideoFromGallery,
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _videoUrlController.text.isEmpty ? Colors.grey.shade300 : const Color(0xFF0F4C43),
                            width: _videoUrlController.text.isEmpty ? 1.5 : 2.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _videoUrlController.text.isEmpty
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.video_call_outlined, size: 40, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Choose Tour Video from Gallery',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Formats supported: MP4, MOV',
                                      style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade400),
                                    ),
                                  ],
                                )
                              : Container(
                                  color: Colors.black.withOpacity(0.04),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.play_circle_fill, size: 48, color: Color(0xFF0F4C43)),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Video Selected from Gallery',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF1E2D27),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 20),
                                            child: Text(
                                              _videoUrlController.text.split('/').last,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.black.withOpacity(0.6),
                                          child: IconButton(
                                            icon: const Icon(Icons.close, size: 14, color: Colors.white),
                                            onPressed: () {
                                              setState(() {
                                                _videoUrlController.clear();
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                    ),
                  ),

                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F4C43),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          isEditing ? 'Save Resort Details' : 'Publish Resort Property',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F4C43),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0xFF0F4C43),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildFormField(
      TextEditingController controller, String label, IconData icon,
      {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E2D27)),
      validator: (val) {
        if (label.contains('Name') && (val == null || val.trim().isEmpty)) {
          return 'Please enter a valid resort name';
        }
        if (label.contains('Price') && (val == null || double.tryParse(val) == null)) {
          return 'Please enter a valid price';
        }
        if (label.contains('Rooms') && (val == null || int.tryParse(val) == null)) {
          return 'Please enter total rooms count';
        }
        if (label.contains('Image') && (val == null || val.trim().isEmpty)) {
          return 'Please enter or upload a resort image';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500),
        prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0F4C43), width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400, size: 16),
          items: items.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val, style: GoogleFonts.inter(color: const Color(0xFF1E2D27), fontSize: 13)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCheckbox(String title, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF0F4C43),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1E2D27), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

}
