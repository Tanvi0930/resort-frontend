import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_configue.dart';
import '../utils/favorites_manager.dart';
import '../widgets/resort_image_widget.dart';
import 'user_resort_details_screen.dart';

class ExploreTab extends StatefulWidget {
  final String userName;

  const ExploreTab({super.key, required this.userName});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  List<dynamic> _allResorts = [];
  List<dynamic> _filteredResorts = [];
  List<String> _wishlistedResorts = [];
  bool _isLoading = true;

  String _selectedSort = 'Recommended';
  String _searchQuery = '';
  bool _isGridView = true;

  final List<dynamic> _fallbackMockResorts = [
    {
      'name': 'The Canopy Retreat',
      'location': 'Coorg, Karnataka',
      'rooms': 6,
      'price': 8500.0,
      'rating': 4.9,
      'imageUrl': 'https://images.unsplash.com/photo-1540541338287-41700207dee6?q=80&w=2070',
      'veg': true,
      'nonVeg': true,
      'breakfast': true,
      'breaksnacks': true,
      'category': 'Nature',
      'ratingCount': 428,
      'discount': '-29%',
    },
    {
      'name': 'Azure Bay Resort',
      'location': 'Goa, North Goa',
      'rooms': 3,
      'price': 12000.0,
      'rating': 4.8,
      'imageUrl': 'https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?q=80&w=2070',
      'veg': true,
      'nonVeg': true,
      'breakfast': true,
      'breaksnacks': true,
      'category': 'Beach',
      'ratingCount': 312,
      'discount': '-20%',
    },
    {
      'name': 'The Misty Pines',
      'location': 'Munnar, Kerala',
      'rooms': 8,
      'price': 6200.0,
      'rating': 4.7,
      'imageUrl': 'https://images.unsplash.com/photo-1584132967334-10e028bd69f7?q=80&w=2070',
      'veg': true,
      'nonVeg': false,
      'breakfast': true,
      'breaksnacks': false,
      'category': 'Mountain',
      'ratingCount': 195,
      'discount': '-27%',
    },
    {
      'name': 'Sapphire Sands',
      'location': 'Lakshadweep Islands',
      'rooms': 5,
      'price': 28000.0,
      'rating': 5.0,
      'imageUrl': 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?q=80&w=2070',
      'veg': true,
      'nonVeg': true,
      'breakfast': true,
      'breaksnacks': true,
      'category': 'Luxury',
      'ratingCount': 512,
      'discount': '-20%',
    },
    {
      'name': 'Mountain Serenity',
      'location': 'Bengaluru, Karnataka',
      'rooms': 4,
      'price': 3999.0,
      'rating': 4.6,
      'imageUrl': 'https://images.unsplash.com/photo-1470770841072-f978cf4d019e?q=80&w=2070',
      'veg': true,
      'nonVeg': true,
      'breakfast': false,
      'breaksnacks': true,
      'category': 'Mountain',
      'ratingCount': 88,
      'discount': '-5%',
    }
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favs = await FavoritesManager.getFavorites();
    if (!mounted) return;
    setState(() {
      _wishlistedResorts = favs;
    });
  }

  Future<void> _toggleFavorite(String name) async {
    final isFav = await FavoritesManager.toggleFavorite(name);
    if (!mounted) return;
    setState(() {
      if (isFav) {
        _wishlistedResorts.add(name);
      } else {
        _wishlistedResorts.remove(name);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFav ? 'Added to Wishlist' : 'Removed from Wishlist'),
        duration: const Duration(seconds: 1),
      ),
    );
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

      for (var mock in _fallbackMockResorts) {
        if (!nameSet.contains(mock['name'].toString().trim().toLowerCase())) {
          merged.add(mock);
        }
      }

      setState(() {
        _allResorts = merged;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      debugPrint('Error loading resorts: $e');
      setState(() {
        _allResorts = _fallbackMockResorts;
        _isLoading = false;
        _applyFilters();
      });
    }
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void _applyFilters() {
    List<dynamic> temp = List.from(_allResorts);

    if (_searchQuery.isNotEmpty) {
      temp = temp.where((resort) {
        final name = resort['name']?.toString().toLowerCase() ?? '';
        final loc = resort['location']?.toString().toLowerCase() ?? '';
        final cat = resort['category']?.toString().toLowerCase() ?? '';
        return name.contains(_searchQuery.toLowerCase()) || 
               loc.contains(_searchQuery.toLowerCase()) || 
               cat.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply sorting
    if (_selectedSort == 'Popular') {
      temp.sort((a, b) => ((b['rating'] ?? 0.0) as num).compareTo((a['rating'] ?? 0.0) as num));
    } else if (_selectedSort == 'Lowest Price') {
      temp.sort((a, b) => ((a['price'] ?? 0.0) as num).compareTo((b['price'] ?? 0.0) as num));
    } else if (_selectedSort == 'Highest Price') {
      temp.sort((a, b) => ((b['price'] ?? 0.0) as num).compareTo((a['price'] ?? 0.0) as num));
    }

    setState(() {
      _filteredResorts = temp;
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Filter Resorts',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),
              Text('Sort By', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: ['Recommended', 'Popular', 'Lowest Price', 'Highest Price'].map((sortType) {
                  final isSelected = _selectedSort == sortType;
                  return ChoiceChip(
                    label: Text(sortType),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0F9D94),
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                    onSelected: (selected) {
                      if (selected) {
                        Navigator.pop(context);
                        setState(() {
                          _selectedSort = sortType;
                          _applyFilters();
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F9D94)))
          : Column(
              children: [
                // 1. Top Bar (matching home_screen.dart style)
                _buildHeader(),

                // 2. Search & Filter Bar
                _buildSearchAndFilterSection(),

                // 3. Resorts Grid / List Content
                Expanded(
                  child: _filteredResorts.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _fetchData,
                          color: const Color(0xFF0F9D94),
                          child: _isGridView ? _buildGridContent() : _buildListContent(),
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
              // User Profile & Title
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
                        'Explore Resorts',
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

              // Action: Notification Button
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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No new notifications')),
                        );
                      },
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
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        children: [
          // Search Field + Mic Button
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F9D94).withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      icon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                      hintText: 'Search by name, city, type...',
                      hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F9D94),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F9D94).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.mic, color: Colors.white, size: 22),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Voice search active...')),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filter Action Pills
          Row(
            children: [
              // Filters Button
              InkWell(
                onTap: _showFilterBottomSheet,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tune, color: Color(0xFF0F9D94), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Filters',
                        style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Map View Button
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Map View mode coming soon!')),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.map_outlined, color: Color(0xFF0F9D94), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Map View',
                        style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Grid/List View Toggle Button
              InkWell(
                onTap: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Icon(
                    _isGridView ? Icons.format_list_bulleted : Icons.grid_view,
                    color: const Color(0xFF0F9D94),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildGridContent() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: _filteredResorts.length,
      itemBuilder: (context, index) {
        final resort = _filteredResorts[index];
        return _buildGridResortCard(resort);
      },
    );
  }

  Widget _buildListContent() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredResorts.length,
      itemBuilder: (context, index) {
        final resort = _filteredResorts[index];
        return _buildListResortCard(resort);
      },
    );
  }

  Widget _buildGridResortCard(dynamic resort) {
    final name = resort['name'] ?? 'Resort Stay';
    final location = resort['location'] ?? 'Location';
    final price = (resort['price'] ?? 0.0).toDouble();
    final rating = resort['rating'] ?? 4.5;
    final imageUrl = resort['imageUrl'] ?? 'https://images.unsplash.com/photo-1540541338287-41700207dee6?q=80&w=2070';
    final discount = resort['discount'] ?? '-20%';
    final isWishlisted = _wishlistedResorts.contains(name);

    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserResortDetailsScreen(resortData: resort),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Container with heart icon and discount badge
              Stack(
                children: [
                  Image.network(
                    imageUrl,
                    height: 125,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      height: 125,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 40, color: Colors.grey),
                    ),
                  ),

                  // Favorite Heart Button (Top Right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: () => _toggleFavorite(name),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isWishlisted ? Icons.favorite : Icons.favorite_border,
                          color: isWishlisted ? Colors.redAccent : Colors.grey.shade600,
                          size: 18,
                        ),
                      ),
                    ),
                  ),

                  // Discount Badge (Bottom Left)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4D4F),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        discount,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Content Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  location,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                rating.toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        '₹${price.toStringAsFixed(0)}/night',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F9D94),
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
    );
  }

  Widget _buildListResortCard(dynamic resort) {
    final name = resort['name'] ?? 'Resort Stay';
    final location = resort['location'] ?? 'Location';
    final price = (resort['price'] ?? 0.0).toDouble();
    final rating = resort['rating'] ?? 4.5;
    final imageUrl = resort['imageUrl'] ?? 'https://images.unsplash.com/photo-1540541338287-41700207dee6?q=80&w=2070';
    final isWishlisted = _wishlistedResorts.contains(name);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserResortDetailsScreen(resortData: resort),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ResortImageWidget(
                    resort: Map<String, dynamic>.from(resort as Map),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: InkWell(
                      onTap: () => _toggleFavorite(name),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(
                          isWishlisted ? Icons.favorite : Icons.favorite_border,
                          color: isWishlisted ? Colors.redAccent : Colors.grey.shade600,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(rating.toString(), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(location, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('₹${price.toStringAsFixed(0)}/night', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F9D94))),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => UserResortDetailsScreen(resortData: resort)),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F9D94),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 0,
                          ),
                          child: Text('View Details', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
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
          Icon(Icons.search_off_outlined, size: 70, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Resorts Found',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with a different keyword.',
            style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

