import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_configue.dart';

class BookingScreen extends StatefulWidget {
  final dynamic resortData;

  const BookingScreen({super.key, required this.resortData});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String _selectedCategory = 'Family';
  int _peopleCount = 1;
  int _roomsCount = 1;
  int _lockersCount = 0;
  
  String _transportOption = 'None';

  bool _isSubmitting = false;

  double get _totalPrice {
    final double basePrice = (widget.resortData['price'] ?? 0).toDouble();
    double total = basePrice * _peopleCount; // Base price is per user
    
    // Add transport costs
    if (_transportOption.contains('Pick-up') || _transportOption.contains('Drop')) total += 20.0;
    else if (_transportOption.contains('Both')) total += 35.0;
    
    // Lockers cost
    total += (_lockersCount * 5.0);
    return total;
  }

  Future<void> _submitBooking() async {
    setState(() => _isSubmitting = true);

    List<String> servicesList = [];
    if (_transportOption != 'None') {
      servicesList.add(_transportOption.split(' ')[0]); // 'Pick-up', 'Drop', or 'Both'
    }
    String serviceOptionsStr = servicesList.join(", ");

    final Map<String, dynamic> bookingPayload = {
      "resortName": widget.resortData['name'],
      "guestName": "Tanvi", // Hardcoded for now, could get from user profile
      "date": DateTime.now().toIso8601String().split('T')[0],
      "status": "Pending",
      "amount": _totalPrice,
      "category": _selectedCategory,
      "peopleCount": _peopleCount,
      "roomsCount": _roomsCount,
      "lockersCount": _lockersCount,
      "serviceOptions": serviceOptionsStr,
    };

    try {
      final response = await http.post(
        Uri.parse('${ApiConfigue.baseUrl}/api/bookings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bookingPayload),
      );

      setState(() => _isSubmitting = false);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Your booking has been created successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                  Navigator.of(context).pop(); // close booking screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        _showError('Failed to create booking. Server responded with ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F5),
      appBar: AppBar(
        title: const Text('Book Your Stay', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.resortData['name']}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A2B)),
            ),
            const SizedBox(height: 20),
            
            // Category Dropdown
            const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedCategory,
                  items: ['Group', 'Family', 'School trips', 'Other'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _selectedCategory = newValue);
                    }
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Counters
            _buildCounter('People', _peopleCount, (val) => setState(() => _peopleCount = val)),
            const SizedBox(height: 16),
            _buildCounter(
              'Rooms (Max ${widget.resortData['rooms'] ?? 0})', 
              _roomsCount, 
              (val) => setState(() => _roomsCount = val), 
              min: 0, 
              max: widget.resortData['rooms'] ?? 0
            ),
            const SizedBox(height: 16),
            _buildCounter('Lockers (Optional)', _lockersCount, (val) => setState(() => _lockersCount = val), min: 0),
            
            const SizedBox(height: 24),
            
            // Services
            const Text('Transport Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _transportOption,
                  items: ['None', 'Pick-up (+\$20)', 'Drop (+\$20)', 'Both (+\$35)'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _transportOption = newValue);
                    }
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 100), // padding for bottom bar
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Price', style: TextStyle(color: Colors.grey)),
                Text(
                  '\$$_totalPrice',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3E7C59)),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3E7C59),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Pay Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounter(String title, int currentValue, ValueChanged<int> onChanged, {int min = 1, int? max}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: currentValue > min ? const Color(0xFF3E7C59) : Colors.grey,
                onPressed: currentValue > min ? () => onChanged(currentValue - 1) : null,
              ),
              Text(
                '$currentValue',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: (max == null || currentValue < max) ? const Color(0xFF3E7C59) : Colors.grey,
                onPressed: (max == null || currentValue < max) ? () => onChanged(currentValue + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
