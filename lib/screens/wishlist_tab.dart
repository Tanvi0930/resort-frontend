import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_configue.dart';
import '../utils/favorites_manager.dart';
import 'user_resort_details_screen.dart';

class WishlistTab extends StatefulWidget {
  final String userName;

  const WishlistTab({super.key, required this.userName});

  @override
  State<WishlistTab> createState() => _WishlistTabState();
}

class _WishlistTabState extends State<WishlistTab> {
  List<dynamic> _wishlistedResorts = [];
  List<dynamic> _filteredWishlist = [];
  bool _isLoading = true;
  final String _selectedCategory = 'All';

  final List<dynamic> _defaultMockResorts = [
    {
      'name': 'Azure Bay Resort',
      'location': 'Goa, North Goa',
      'rooms': 3,
      'price': 12000.0,
      'originalPrice': 15000.0,
      'rating': 4.8,
      'ratingCount': 312,
      'discount': '-20% OFF',
      'roomsLeftText': 'Only 3 left!',
      'imageUrl': 'https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?q=80&w=2070',
      'veg': true,
      'nonVeg': true,
      'breakfast': true,
      'breaksnacks': true,
      'category': 'Beach',
    },
    {
      'name': 'Sapphire Sands',
      'location': 'Lakshadweep Islands',
      'rooms': 2,
      'price': 28000.0,
      'originalPrice': 35000.0,
      'rating': 5.0,
      'ratingCount': 89,
      'discount': '-20% OFF',
      'roomsLeftText': 'Only 2 left!',
      'imageUrl': 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?q=80&w=2070',
      'veg': true,
      'nonVeg': true,
      'breakfast': true,
      'breaksnacks': true,
      'category': 'Luxury',
    },
    {
      'name': 'The Canopy Retreat',
      'location': 'Coorg, Karnataka',
      'rooms': 4,
      'price': 8500.0,
      'originalPrice': 12000.0,
      'rating': 4.9,
      'ratingCount': 428,
      'discount': '-29% OFF',
      'roomsLeftText': 'Only 4 left!',
      'imageUrl': 'https://images.unsplash.com/photo-1540541338287-41700207dee6?q=80&w=2070',
      'veg': true,
      'nonVeg': true,
      'breakfast': true,
      'breaksnacks': true,
      'category': 'Nature',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfigue.baseUrl}/api/resorts'));
      List<dynamic> fetchedResorts = [];
      if (res.statusCode == 200) {
        fetchedResorts = json.decode(res.body) as List<dynamic>;
      }

      final Set<String> nameSet = {};
      final List<dynamic> merged = [];
      
      for (var r in fetchedResorts) {
        if (r['name'] != null) {
          nameSet.add(r['name'].toString().trim().toLowerCase());
          merged.add(r);
        }
      }

      for (var mock in _defaultMockResorts) {
        if (!nameSet.contains(mock['name'].toString().trim().toLowerCase())) {
          merged.add(mock);
        }
      }

      final favorites = await FavoritesManager.getFavorites();

      if (favorites.isEmpty) {
        await FavoritesManager.toggleFavorite('Azure Bay Resort');
        await FavoritesManager.toggleFavorite('Sapphire Sands');
        favorites.add('Azure Bay Resort');
        favorites.add('Sapphire Sands');
      }

      final wishlisted = merged.where((resort) {
        return favorites.contains(resort['name']?.toString() ?? '');
      }).toList();

      setState(() {
        _wishlistedResorts = wishlisted;
        _applyCategoryFilter();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading wishlist: $e');
      final favorites = await FavoritesManager.getFavorites();
      if (favorites.isEmpty) {
        favorites.add('Azure Bay Resort');
        favorites.add('Sapphire Sands');
      }

      final wishlisted = _defaultMockResorts.where((resort) {
        return favorites.contains(resort['name']?.toString() ?? '');
      }).toList();

      setState(() {
        _wishlistedResorts = wishlisted;
        _applyCategoryFilter();
        _isLoading = false;
      });
    }
  }

  void _applyCategoryFilter() {
    if (_selectedCategory == 'All') {
      _filteredWishlist = List.from(_wishlistedResorts);
    } else {
      _filteredWishlist = _wishlistedResorts.where((r) => r['category'] == _selectedCategory).toList();
    }
  }

  Future<void> _removeFavorite(String resortName) async {
    await FavoritesManager.toggleFavorite(resortName);
    if (!mounted) return;
    setState(() {
      _wishlistedResorts.removeWhere((r) => r['name'] == resortName);
      _applyCategoryFilter();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "$resortName" from Wishlist'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      body: Column(
        children: [
          // 1. Unified White Header
          _buildHeader(),

          // 2. Wishlist Items Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F9D94)))
                : _filteredWishlist.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchData,
                        color: const Color(0xFF0F9D94),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          children: [
                            ..._filteredWishlist.map((resort) => _buildCustomWishlistCard(resort)),
                            const SizedBox(height: 12),
                            _buildCompareResortsButton(),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F9D94).withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F9D94), Color(0xFF0A7B74)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F9D94).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        'My Wishlist',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  // Wishlist Count Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4F1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite, color: Color(0xFF0F9D94), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${_wishlistedResorts.length}',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF0F9D94),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Stack(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: Color(0xFF334155),
                            size: 20,
                          ),
                          onPressed: () {},
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F9D94),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded, size: 70, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Saved Resorts Found',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Text(
            'Explore stay options and tap ❤️ to add resorts to your wishlist.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomWishlistCard(dynamic resort) {
    final name = resort['name']?.toString() ?? 'Resort Stay';
    final location = resort['location']?.toString() ?? 'Goa, India';
    final priceNum = (resort['price'] ?? 12000.0) as num;
    final originalPriceNum = (resort['originalPrice'] ?? (priceNum * 1.25)) as num;
    final ratingNum = (resort['rating'] ?? 4.8) as num;
    final ratingCount = resort['ratingCount'] ?? 312;
    final discountText = resort['discount'] ?? '-20% OFF';
    final roomsLeftText = resort['roomsLeftText'] ?? 'Only ${resort['rooms'] ?? 3} rooms left!';
    final imageUrl = resort['imageUrl']?.toString() ?? 'https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?q=80&w=2070';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 148,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserResortDetailsScreen(resortData: resort),
            ),
          ).then((_) => _fetchData());
        },
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            // Left Image with Discount Pill
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              child: SizedBox(
                width: 125,
                height: double.infinity,
                child: Stack(
                  children: [
                    Image.network(
                      imageUrl,
                      width: 125,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: Colors.teal.shade50,
                        child: const Icon(Icons.image, color: Colors.teal),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4D4F),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          discountText,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right Content Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Row 1: Resort Title + Share & Heart Icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Sharing "$name"...')),
                                );
                              },
                              child: const Icon(
                                Icons.share_outlined,
                                size: 18,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _removeFavorite(name),
                              child: const Icon(
                                Icons.favorite,
                                size: 18,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Row 2: Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Row 3: Rating
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: Color(0xFFFFB800),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$ratingNum',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '($ratingCount)',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),

                    // Row 4: Price & Book Now Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₹${priceNum.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F9D94),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '₹${originalPriceNum.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF94A3B8),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserResortDetailsScreen(resortData: resort),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F9D94),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Book Now',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Row 5: Urgency text
                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          size: 12,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          roomsLeftText,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompareResortsButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0F9D94), width: 1.2),
      ),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comparing saved resorts...')),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.swap_vert_rounded,
              color: Color(0xFF0F9D94),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Compare Resorts',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F9D94),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
