import 'package:flutter/material.dart';
import '../widgets/resort_image_widget.dart';
import 'booking_screen.dart';

class UserResortDetailsScreen extends StatelessWidget {
  final dynamic resortData;

  const UserResortDetailsScreen({super.key, required this.resortData});

  @override
  Widget build(BuildContext context) {
    final String name = resortData['name'] ?? 'Resort Name';
    final String location = resortData['location'] ?? 'Location';
    final double price = (resortData['price'] ?? 0).toDouble();
    final double rating = (resortData['rating'] ?? 4.5).toDouble();
    final bool veg = resortData['veg'] ?? false;
    final bool nonVeg = resortData['nonVeg'] ?? false;
    final bool breakfast = resortData['breakfast'] ?? false;
    final bool breaksnacks = resortData['breaksnacks'] ?? false;
    final String category = resortData['category'] ?? '';
    final int rooms = resortData['rooms'] ?? 0;
    final int lockers = resortData['lockerNo'] ?? 0;
    final String serviceOption = resortData['serviceOption'] ?? '';

    final Map<String, dynamic> resortMap = resortData is Map<String, dynamic> 
        ? resortData 
        : Map<String, dynamic>.from(resortData as Map);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: ResortImageWidget(
                resort: resortMap,
                fit: BoxFit.cover,
                height: 250,
                width: double.infinity,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            rating.toString(),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoBox(Icons.meeting_room, '$rooms Rooms Available'),
                      const SizedBox(width: 12),
                      _buildInfoBox(Icons.lock, '$lockers Lockers Available'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Amenities & Services',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      if (veg) _buildChip('Veg Food Available'),
                      if (nonVeg) _buildChip('Non-Veg Food Available'),
                      if (breakfast) _buildChip('Breakfast Included'),
                      if (breaksnacks) _buildChip('Snacks Included'),
                      if (category.isNotEmpty) _buildChip(category),
                      if (serviceOption.isNotEmpty) _buildChip(serviceOption),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'About this resort',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enjoy a relaxing stay at this beautiful resort located in a prime area. '
                    'Experience top-notch amenities, great food, and comfortable rooms.',
                    style: TextStyle(color: Colors.black54, height: 1.5),
                  ),
                  const SizedBox(height: 100), // padding for bottom bar
                ],
              ),
            ),
          ),
        ],
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
                const Text('Price', style: TextStyle(color: Colors.grey)),
                Text(
                  '\$$price / user',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF112233)),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingScreen(resortData: resortData),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF112233),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Book Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEFF5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF112233), fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildInfoBox(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF112233)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}
