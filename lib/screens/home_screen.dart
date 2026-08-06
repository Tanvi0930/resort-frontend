import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_configue.dart';
import '../utils/favorites_manager.dart';
import '../widgets/resort_image_widget.dart';
import 'user_resort_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({super.key, this.userName = 'Arjun Sharma'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _locations = [];
  List<dynamic> _allResorts = [];
  List<dynamic> _filteredResorts = [];
  
  List<String> _states = [];
  List<String> _cities = [];

  String? _selectedState;
  String? _selectedCity;

  final String _selectedCategory = 'All';
  String _searchQuery = '';
  
  bool _isLoading = true;
  int _bannerIndex = 0;
  List<String> _wishlistedResorts = [];

  // Banner properties
  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'Mountain Serenity',
      'subtitle': 'Weekend getaways from ₹3,999',
      'image': 'https://images.unsplash.com/photo-1470770841072-f978cf4d019e?q=80&w=2070',
      'price': 3999,
    },
    {
      'title': 'The Canopy Retreat',
      'subtitle': 'Curated forest stays from ₹8,500',
      'image': 'https://images.unsplash.com/photo-1540541338287-41700207dee6?q=80&w=2070',
      'price': 8500,
    },
    {
      'title': 'Azure Bay Resort',
      'subtitle': 'Sandy beach getaways from ₹12,000',
      'image': 'https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?q=80&w=2070',
      'price': 12000,
    }
  ];

  // Mock resorts representing screenshot properties in case the DB is sparse
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
      'location': 'Manali, Himachal Pradesh',
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
      'discount': '-15%',
    },
    {
      'name': 'Sapphire Sands',
      'location': 'Kovalam, Kerala',
      'rooms': 5,
      'price': 28000.0,
      'rating': 4.9,
      'imageUrl': 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?q=80&w=2070',
      'veg': true,
      'nonVeg': true,
      'breakfast': true,
      'breaksnacks': true,
      'category': 'Luxury',
      'ratingCount': 512,
      'discount': '-10%',
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

  void _onStateSelected(String? state) {
    if (state == null) return;
    
    final Set<String> citySet = {};
    for (var loc in _locations) {
      if (loc['state'] != null && loc['city'] != null) {
        String locState = loc['state'].toString().trim().toLowerCase();
        if (locState.isNotEmpty) {
           locState = locState[0].toUpperCase() + locState.substring(1);
           if (locState == state) {
             String cityStr = loc['city'].toString().trim().toLowerCase();
             if (cityStr.isNotEmpty) {
               cityStr = cityStr[0].toUpperCase() + cityStr.substring(1);
               citySet.add(cityStr);
             }
           }
        }
      }
    }

    List<String> citiesList = citySet.toList();
    if (citiesList.isEmpty) {
      if (state == 'Karnataka') citiesList = ['Bengaluru', 'Coorg'];
      else if (state == 'Goa') citiesList = ['Goa', 'North Goa'];
      else if (state == 'Himachal Pradesh') citiesList = ['Manali'];
      else if (state == 'Kerala') citiesList = ['Kovalam'];
    }

    setState(() {
      _selectedState = state;
      _cities = citiesList;
      _selectedCity = citiesList.isNotEmpty ? citiesList.first : null;
      _applyFilters();
    });
  }

  void _onCitySelected(String? city) {
    setState(() {
      _selectedCity = city;
      _applyFilters();
    });
  }

  Future<void> _fetchData() async {
    try {
      final locRes = await http.get(Uri.parse('${ApiConfigue.baseUrl}/api/locations'));
      final resRes = await http.get(Uri.parse('${ApiConfigue.baseUrl}/api/resorts'));

      List<dynamic> fetchedLocs = [];
      List<dynamic> fetchedResorts = [];

      if (locRes.statusCode == 200) {
        fetchedLocs = json.decode(locRes.body) as List<dynamic>;
      }
      if (resRes.statusCode == 200) {
        fetchedResorts = json.decode(resRes.body) as List<dynamic>;
      }

      final Set<String> nameSet = {};
      final List<dynamic> mergedResorts = [];

      for (var r in fetchedResorts) {
        if (r['name'] != null) {
          nameSet.add(r['name'].toString().trim().toLowerCase());
          mergedResorts.add(r);
        }
      }

      for (var mock in _fallbackMockResorts) {
        if (!nameSet.contains(mock['name'].toString().trim().toLowerCase())) {
          mergedResorts.add(mock);
        }
      }

      final Set<String> stateSet = {};
      for (var loc in fetchedLocs) {
        if (loc['state'] != null) {
          String stateStr = loc['state'].toString().trim().toLowerCase();
          if (stateStr.isNotEmpty) {
            stateStr = stateStr[0].toUpperCase() + stateStr.substring(1);
            stateSet.add(stateStr);
          }
        }
      }

      List<String> statesList = stateSet.toList();
      if (statesList.isEmpty) {
        statesList = ['Karnataka', 'Goa', 'Himachal Pradesh', 'Kerala'];
      }

      String? defaultState = statesList.contains('Karnataka') ? 'Karnataka' : (statesList.isNotEmpty ? statesList.first : null);
      
      final Set<String> citySet = {};
      for (var loc in fetchedLocs) {
        if (loc['state'] != null && loc['city'] != null) {
          String locState = loc['state'].toString().trim().toLowerCase();
          locState = locState.isNotEmpty ? (locState[0].toUpperCase() + locState.substring(1)) : '';
          if (locState == defaultState) {
            String cityStr = loc['city'].toString().trim().toLowerCase();
            cityStr = cityStr.isNotEmpty ? (cityStr[0].toUpperCase() + cityStr.substring(1)) : '';
            if (cityStr.isNotEmpty) {
              citySet.add(cityStr);
            }
          }
        }
      }

      List<String> citiesList = citySet.toList();
      if (citiesList.isEmpty && defaultState == 'Karnataka') {
        citiesList = ['Bengaluru', 'Coorg'];
      }
      
      String? defaultCity = citiesList.contains('Bengaluru') ? 'Bengaluru' : (citiesList.isNotEmpty ? citiesList.first : null);

      setState(() {
        _locations = fetchedLocs;
        _allResorts = mergedResorts;
        _states = statesList;
        _cities = citiesList;
        _selectedState = defaultState;
        _selectedCity = defaultCity;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      debugPrint('Error fetching data: $e');
      final List<String> fallbackStates = ['Karnataka', 'Goa', 'Himachal Pradesh', 'Kerala'];
      final List<String> fallbackCities = ['Bengaluru', 'Coorg'];
      setState(() {
        _allResorts = _fallbackMockResorts;
        _states = fallbackStates;
        _cities = fallbackCities;
        _selectedState = 'Karnataka';
        _selectedCity = 'Bengaluru';
        _isLoading = false;
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    List<dynamic> temp = List.from(_allResorts);

    if (_searchQuery.isNotEmpty) {
      temp = temp.where((r) {
        final name = r['name']?.toString().toLowerCase() ?? '';
        final loc = r['location']?.toString().toLowerCase() ?? '';
        return name.contains(_searchQuery.toLowerCase()) || loc.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_selectedState != null) {
      temp = temp.where((r) {
        final loc = r['location']?.toString().toLowerCase() ?? '';
        return loc.contains(_selectedState!.toLowerCase());
      }).toList();
    }

    if (_selectedCity != null) {
      temp = temp.where((r) {
        final loc = r['location']?.toString().toLowerCase() ?? '';
        return loc.contains(_selectedCity!.toLowerCase());
      }).toList();
    }

    if (_selectedCategory != 'All') {
      temp = temp.where((r) {
        final cat = r['category']?.toString().toLowerCase() ?? '';
        return cat.contains(_selectedCategory.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredResorts = temp;
    });
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F9D94)))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Bar (standalone header panel)
                  _buildHeader(),

                  // 2. Banner Carousel (resort card) - shown first
                  const SizedBox(height: 20),
                  _buildBannerCarousel(),

                  // 3. Search bar & location
                  const SizedBox(height: 20),
                  _buildMainBodyHeader(),

                  _buildOldLocationDropdowns(),

                  // 4. Top Rated Section
                  const SizedBox(height: 28),
                  _buildTopRatedSection(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    return 'Good Evening';
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
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // User Profile & Greeting
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
                            _getGreeting(),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            widget.userName,
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
                          onPressed: () => _showNotificationsSheet(context),
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

  void _showLocationPickerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    'Select Destination Location',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('State', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedState,
                        hint: const Text('Select State'),
                        items: _states.map((st) => DropdownMenuItem(value: st, child: Text(st))).toList(),
                        onChanged: (val) {
                          setModalState(() {});
                          _onStateSelected(val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('City', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedCity,
                        hint: const Text('Select City'),
                        items: _cities.map((ct) => DropdownMenuItem(value: ct, child: Text(ct))).toList(),
                        onChanged: (val) {
                          setModalState(() {});
                          _onCitySelected(val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F9D94),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Apply Location', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showNotificationsSheet(BuildContext context) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Notifications', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(12)),
                    child: Text('2 New', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0284C7), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Color(0xFFE6F4F1), shape: BoxShape.circle),
                  child: const Icon(Icons.local_offer, color: Color(0xFF0F9D94), size: 20),
                ),
                title: Text('Monsoon Special Offer', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('Get up to 30% off on hill station resorts this weekend!', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
                  child: const Icon(Icons.star, color: Color(0xFFD97706), size: 20),
                ),
                title: Text('Featured Stays Available', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('New luxury villa added in Coorg, Karnataka.', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainBodyHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location Indicator Display
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_outlined, color: Color(0xFF0F9D94), size: 18),
              const SizedBox(width: 4),
              Text(
                _selectedCity != null && _selectedState != null
                    ? '$_selectedCity, $_selectedState'
                    : 'Select Location',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6F8D8B), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F9D94).withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                        _applyFilters();
                      });
                    },
                    style: const TextStyle(color: Color(0xFF173B3A)),
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search, color: Color(0xFF6F8D8B)),
                      hintText: 'Search resorts, destinations...',
                      hintStyle: TextStyle(fontSize: 14, color: Color(0xFF6F8D8B)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F9D94),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F9D94).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune_rounded, color: Colors.white),
                  onPressed: () => _showLocationPickerBottomSheet(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOldLocationDropdowns() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Location',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF173B3A)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedState,
                      hint: const Text('State', style: TextStyle(color: Colors.black87, fontSize: 14)),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87, size: 16),
                      items: _states.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(color: Colors.black87, fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: _onStateSelected,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedCity,
                      hint: const Text('City', style: TextStyle(color: Colors.black87, fontSize: 14)),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87, size: 16),
                      items: _cities.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(color: Colors.black87, fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: _onCitySelected,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            itemCount: _banners.length,
            onPageChanged: (index) {
              setState(() {
                _bannerIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  image: DecorationImage(
                    image: NetworkImage(banner['image']),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        banner['subtitle'].toString().toUpperCase(),
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        banner['title'],
                        style: GoogleFonts.inter(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          // Find this resort and navigate to details
                          final matching = _allResorts.firstWhere(
                            (r) => r['name'].toString().toLowerCase().contains(banner['title'].toString().toLowerCase()),
                            orElse: () => _fallbackMockResorts.first,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => UserResortDetailsScreen(resortData: matching)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC69E66),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Book Now',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _banners.asMap().entries.map((entry) {
            final active = _bannerIndex == entry.key;
            return Container(
              width: active ? 16 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFC69E66) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Top Rated Section (Vertical cards with horizontal details)
  Widget _buildTopRatedSection() {
    // Use filteredResorts so state/city dropdown controls what shows
    final list = _filteredResorts.toList();
    final locationLabel = _selectedCity != null
        ? _selectedCity!
        : (_selectedState ?? 'All Locations');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resorts in $locationLabel',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF173B3A)),
                  ),
                  Text(
                    '${list.length} resort${list.length == 1 ? '' : 's'} found',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6F8D8B)),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'View All',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F9D94), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right, color: Color(0xFF0F9D94), size: 16),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.location_off_outlined, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'No resorts found in $locationLabel',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF173B3A)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Try selecting a different state or city',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6F8D8B)),
                  ),
                ],
              ),
            ),
          )
        else
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final resort = list[index];
            final name = resort['name'] ?? 'Resort Stay';
            final discount = resort['discount'] ?? '-29%';
            final rating = resort['rating'] ?? 4.5;
            final isFav = _wishlistedResorts.contains(name);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UserResortDetailsScreen(resortData: resort)),
                  ).then((_) => _loadFavorites());
                },
                child: Row(
                  children: [
                    // Left image
                    Stack(
                      children: [
                        ResortImageWidget(
                          resort: Map<String, dynamic>.from(resort),
                          height: 84,
                          width: 84,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              discount,
                              style: GoogleFonts.inter(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Right details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF173B3A)),
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  isFav ? Icons.favorite : Icons.favorite_border,
                                  color: isFav ? Colors.red : Colors.grey,
                                  size: 18,
                                ),
                                onPressed: () => _toggleFavorite(name),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade400),
                              const SizedBox(width: 2),
                              Text(
                                resort['location'] ?? 'Location',
                                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF6F8D8B)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.orange, size: 12),
                                  const SizedBox(width: 2),
                                  Text(
                                    '$rating ',
                                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '(${resort['ratingCount'] ?? 428})',
                                    style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF6F8D8B)),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    '₹${(resort['price'] ?? 0.0).toStringAsFixed(0)}',
                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF173B3A)),
                                  ),
                                  Text(
                                    '/night',
                                    style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF6F8D8B)),
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
          },
        ),
      ],
    );
  }
}

