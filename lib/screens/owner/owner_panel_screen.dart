import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../api_configue.dart';
import 'owner_dashboard_view.dart';
import 'owner_resort_details_view.dart';
import 'owner_resort_images_view.dart';
import '../admin/admin_locations_view.dart';
import '../admin/admin_bookings_view.dart';
import '../login_screen.dart';
import '../../services/auth_service.dart';

class OwnerPanelScreen extends StatefulWidget {
  final String? ownerName;
  final String? ownerRole;

  const OwnerPanelScreen({
    super.key,
    this.ownerName,
    this.ownerRole,
  });

  @override
  State<OwnerPanelScreen> createState() => _OwnerPanelScreenState();
}

class _OwnerPanelScreenState extends State<OwnerPanelScreen> {
  // 0=Dashboard, 1=Location, 2=Bookings, 3=Resort Details, 4=Resort Images
  int _selectedMenuIndex = 0;

  // In-memory Shared Data State
  late List<Map<String, dynamic>> _resorts;
  late List<Map<String, dynamic>> _locations;
  late List<Map<String, dynamic>> _bookings;
  late List<Map<String, dynamic>> _activities;

  @override
  void initState() {
    super.initState();

    _resorts = [];

    _locations = [];

    _bookings = [];

    _activities = [];

    _fetchLocationsFromBackend();
    _fetchResortsFromBackend();
    _fetchBookingsFromBackend();
  }

  Future<void> _fetchResortsFromBackend() async {
    try {
      final baseUrl = ApiConfigue.baseUrl.replaceAll(' ', '');
      final response = await http.get(Uri.parse('$baseUrl/api/resorts'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final allResorts = data.map((item) {
          return {
            'id': (item['id'] ?? '').toString(),
            'name': item['name'] ?? '',
            'location': item['location'] ?? '',
            'contactNo': item['contactNo'] ?? '',
            'email': item['email'] ?? '',
            'rooms': item['rooms'] ?? 0,
            'lockerNo': item['lockerNo'] ?? 0,
            'price': item['price'] ?? 0.0,
            'serviceOption': item['serviceOption'] ?? '',
            'imageUrl': item['imageUrl'] ?? '',
            'rating': item['rating'] ?? 4.5,
            'description': item['description'] ?? '',
            'category': item['category'] ?? 'Family',
            'foodDetails': {
              'veg': item['veg'] ?? false,
              'nonVeg': item['nonVeg'] ?? false,
              'breakfast': item['breakfast'] ?? false,
              'breaksnacks': item['breaksnacks'] ?? false,
            }
          };
        }).toList();

        // Strict Account-Wise Filtering for Owner Panel:
        final String savedName = await AuthService.getSavedName();
        final String activeOwner = savedName.isNotEmpty ? savedName.trim() : (widget.ownerName ?? '').trim();
        List<Map<String, dynamic>> filteredResorts = allResorts;

        if (activeOwner.isNotEmpty &&
            activeOwner.toLowerCase() != 'owner' &&
            activeOwner.toLowerCase() != 'admin') {
          final cleanOwner = activeOwner.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          final matched = allResorts.where((r) {
            final cleanResort = (r['name'] ?? '').toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
            return cleanResort.contains(cleanOwner) || cleanOwner.contains(cleanResort);
          }).toList();

          if (matched.isNotEmpty) {
            filteredResorts = matched;
          }
        }

        if (mounted) {
          setState(() {
            _resorts = filteredResorts;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching resorts: $e');
    }
  }

  Future<void> _fetchBookingsFromBackend() async {
    try {
      final baseUrl = ApiConfigue.baseUrl.replaceAll(' ', '');
      final response = await http.get(Uri.parse('$baseUrl/api/bookings'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Map<String, dynamic>> parsedBookings = data.map((item) {
          return {
            'id': (item['id'] ?? '').toString(),
            'resortName': item['resortName'] ?? '',
            'guestName': item['guestName'] ?? '',
            'date': item['date'] ?? '',
            'status': item['status'] ?? 'Pending',
            'amount': item['amount'] ?? 0.0,
          };
        }).toList();

        final List<Map<String, dynamic>> dynamicActivities = [];
        for (var b in parsedBookings) {
          final guest = (b['guestName'] ?? '').toString().isNotEmpty ? b['guestName'] : 'Guest';
          final resort = (b['resortName'] ?? '').toString().isNotEmpty ? b['resortName'] : 'Resort';
          dynamicActivities.add({
            'title': 'New booking: $resort ($guest)',
            'time': b['date'] ?? 'Recent',
            'icon': Icons.calendar_today_outlined,
            'color': const Color(0xFF0F4C43),
          });
        }

        if (mounted) {
          setState(() {
            _bookings = parsedBookings;
            _activities = dynamicActivities;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
    }
  }

  Future<void> _fetchLocationsFromBackend() async {
    try {
      final baseUrl = ApiConfigue.baseUrl.replaceAll(' ', '');
      final response =
          await http.get(Uri.parse('$baseUrl/api/locations'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _locations = data.map((item) {
            return {
              'id': (item['id'] ?? '').toString(),
              'city': item['city'] ?? '',
              'state': item['state'] ?? '',
              'pin': item['pin'] ?? '',
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching locations: $e');
    }
  }

  void _addActivityLog(String title, IconData icon, Color color) {
    setState(() {
      _activities.insert(0, {
        'title': title,
        'time': 'Just Now',
        'icon': icon,
        'color': color,
      });
      if (_activities.length > 12) {
        _activities.removeLast();
      }
    });
  }

  // --- Resort State Callbacks ---
  Future<void> _handleResortAdded(Map<String, dynamic> resort) async {
    _addActivityLog('New resort added: ${resort['name']}',
        Icons.add_business_outlined, const Color(0xFF0F4C43));
    try {
      final baseUrl = ApiConfigue.baseUrl.replaceAll(' ', '');
      final response = await http.post(
        Uri.parse('$baseUrl/api/resorts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': resort['name'],
          'location': resort['location'],
          'contactNo': resort['contactNo'],
          'email': resort['email'],
          'rooms': resort['rooms'],
          'lockerNo': resort['lockerNo'],
          'price': resort['price'],
          'serviceOption': resort['serviceOption'],
          'imageUrl': resort['imageUrl'],
          'rating': resort['rating'],
          'description': resort['description'],
          'veg': resort['foodDetails']?['veg'] ?? false,
          'nonVeg': resort['foodDetails']?['nonVeg'] ?? false,
          'breakfast': resort['foodDetails']?['breakfast'] ?? false,
          'breaksnacks': resort['foodDetails']?['breaksnacks'] ?? false,
          'category': resort['category'],
        }),
      );
      if (response.statusCode == 201) {
        _fetchResortsFromBackend();
      }
    } catch (e) {
      debugPrint('Error adding resort: $e');
    }
  }

  Future<void> _handleResortUpdated(int index, Map<String, dynamic> resort) async {
    _addActivityLog('Resort updated: ${resort['name']}',
        Icons.edit_outlined, const Color(0xFFE5A93C));
    try {
      final baseUrl = ApiConfigue.baseUrl.replaceAll(' ', '');
      final response = await http.put(
        Uri.parse('$baseUrl/api/resorts/${resort['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': resort['name'],
          'location': resort['location'],
          'contactNo': resort['contactNo'],
          'email': resort['email'],
          'rooms': resort['rooms'],
          'lockerNo': resort['lockerNo'],
          'price': resort['price'],
          'serviceOption': resort['serviceOption'],
          'imageUrl': resort['imageUrl'],
          'rating': resort['rating'],
          'description': resort['description'],
          'veg': resort['foodDetails']?['veg'] ?? false,
          'nonVeg': resort['foodDetails']?['nonVeg'] ?? false,
          'breakfast': resort['foodDetails']?['breakfast'] ?? false,
          'breaksnacks': resort['foodDetails']?['breaksnacks'] ?? false,
          'category': resort['category'],
        }),
      );
      if (response.statusCode == 200) {
        _fetchResortsFromBackend();
      }
    } catch (e) {
      debugPrint('Error updating resort: $e');
    }
  }

  Future<void> _handleResortDeleted(int index) async {
    final rs = _resorts[index];
    final name = rs['name'];
    _addActivityLog(
        'Resort deleted: $name', Icons.delete_outline, Colors.redAccent);
    try {
      final baseUrl = ApiConfigue.baseUrl.replaceAll(' ', '');
      final response = await http.delete(
        Uri.parse('$baseUrl/api/resorts/${rs['id']}'),
      );
      if (response.statusCode == 200) {
        _fetchResortsFromBackend();
      }
    } catch (e) {
      debugPrint('Error deleting resort: $e');
    }
  }

  // --- Locations State Callbacks ---
  Future<void> _handleLocationAdded(Map<String, dynamic> loc) async {
    _addActivityLog(
        'New location added: ${loc['city']}, ${loc['state']}',
        Icons.add_location_alt_outlined,
        const Color(0xFF0F4C43));
    try {
      final baseUrl = ApiConfigue.baseUrl.replaceAll(' ', '');
      final response = await http.post(
        Uri.parse('$baseUrl/api/locations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'city': loc['city'],
          'state': loc['state'],
          'pin': loc['pin'],
        }),
      );
      if (response.statusCode == 201) {
        _fetchLocationsFromBackend();
      }
    } catch (e) {
      debugPrint('Error adding location: $e');
    }
  }

  Future<void> _handleLocationUpdated(
      int index, Map<String, dynamic> loc) async {
    _addActivityLog(
        'Location updated: ${loc['city']}, ${loc['state']}',
        Icons.edit_location_alt_outlined,
        const Color(0xFFE5A93C));
    try {
      final baseUrl = ApiConfigue.baseUrl.replaceAll(' ', '');
      final response = await http.put(
        Uri.parse('$baseUrl/api/locations/${loc['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'city': loc['city'],
          'state': loc['state'],
          'pin': loc['pin'],
        }),
      );
      if (response.statusCode == 200) {
        _fetchLocationsFromBackend();
      }
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  Future<void> _handleLocationDeleted(int index) async {
    final loc = _locations[index];
    final city = loc['city'];
    _addActivityLog('Location deleted: $city',
        Icons.wrong_location_outlined, Colors.redAccent);
    try {
      final baseUrl = ApiConfigue.baseUrl.replaceAll(' ', '');
      final response = await http.delete(
        Uri.parse('$baseUrl/api/locations/${loc['id']}'),
      );
      if (response.statusCode == 200) {
        _fetchLocationsFromBackend();
      }
    } catch (e) {
      debugPrint('Error deleting location: $e');
    }
  }

  // --- Bookings State Callbacks ---
  Future<void> _handleBookingAdded(Map<String, dynamic> bk) async {
    _addActivityLog(
        'New booking created for ${bk['guestName']}',
        Icons.calendar_today_outlined,
        const Color(0xFF0F4C43));
    try {
      final baseUrl = ApiConfigue.baseUrl.replaceAll(' ', '');
      final response = await http.post(
        Uri.parse('$baseUrl/api/bookings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'resortName': bk['resortName'],
          'guestName': bk['guestName'],
          'date': bk['date'],
          'status': bk['status'],
          'amount': bk['amount'],
        }),
      );
      if (response.statusCode == 201) {
        _fetchBookingsFromBackend();
      }
    } catch (e) {
      debugPrint('Error adding booking: $e');
    }
  }

  Future<void> _handleBookingUpdated(int index, Map<String, dynamic> bk) async {
    _addActivityLog(
        'Booking updated: ${bk['guestName']} (${bk['status']})',
        Icons.edit_calendar_outlined,
        const Color(0xFFE5A93C));
    try {
      final baseUrl = ApiConfigue.baseUrl.replaceAll(' ', '');
      final response = await http.put(
        Uri.parse('$baseUrl/api/bookings/${bk['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'resortName': bk['resortName'],
          'guestName': bk['guestName'],
          'date': bk['date'],
          'status': bk['status'],
          'amount': bk['amount'],
        }),
      );
      if (response.statusCode == 200) {
        _fetchBookingsFromBackend();
      }
    } catch (e) {
      debugPrint('Error updating booking: $e');
    }
  }

  Future<void> _handleBookingDeleted(int index) async {
    final bk = _bookings[index];
    final guest = bk['guestName'];
    _addActivityLog(
        'Booking deleted: $guest', Icons.delete_sweep_outlined, Colors.redAccent);
    try {
      final baseUrl = ApiConfigue.baseUrl.replaceAll(' ', '');
      final response = await http.delete(
        Uri.parse('$baseUrl/api/bookings/${bk['id']}'),
      );
      if (response.statusCode == 200) {
        _fetchBookingsFromBackend();
      }
    } catch (e) {
      debugPrint('Error deleting booking: $e');
    }
  }

  Widget _buildSelectedView() {
    switch (_selectedMenuIndex) {
      case 0:
        return OwnerDashboardView(
          resorts: _resorts,
          bookings: _bookings,
          activities: _activities,
          onNavigate: (index) {
            setState(() {
              _selectedMenuIndex = index;
            });
          },
        );
      case 1:
        return AdminLocationsView(
          locations: _locations,
          onLocationAdded: _handleLocationAdded,
          onLocationUpdated: _handleLocationUpdated,
          onLocationDeleted: _handleLocationDeleted,
        );
      case 2:
        return AdminBookingsView(
          bookings: _bookings,
          users: const [],
          locations: _resorts,
          onBookingAdded: _handleBookingAdded,
          onBookingUpdated: _handleBookingUpdated,
          onBookingDeleted: _handleBookingDeleted,
        );
      case 3:
        return OwnerResortDetailsView(
          resorts: _resorts,
          locations: _locations,
          isAdmin: false,
          onResortAdded: _handleResortAdded,
          onResortUpdated: _handleResortUpdated,
          onResortDeleted: _handleResortDeleted,
        );
      case 4:
        return OwnerResortImagesView(
          resorts: _resorts,
          onResortUpdated: _handleResortUpdated,
          onRefreshResorts: _fetchResortsFromBackend,
        );
      default:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.build_circle_outlined,
                  size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text('Module Under Development',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E2D27))),
              SizedBox(height: 8),
              Text('This management module is currently under development.',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
    }
  }

  String _getMenuTitle(int index) {
    const titles = {
      0: 'Dashboard',
      1: 'Location',
      2: 'Bookings',
      3: 'Resort Details',
      4: 'Resort Images',
    };
    return titles[index] ?? 'Panel';
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1100;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      drawer: Drawer(
        child: SafeArea(child: _buildSidebarContents(context)),
      ),
      body: Row(
        children: [
          // Sidebar on Desktop
          if (isDesktop)
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(5, 0),
                  ),
                ],
              ),
              child: SafeArea(child: _buildSidebarContents(context)),
            ),

          // Main Screen Area
          Expanded(
            child: Column(
              children: [
                _buildHeaderBar(context, isDesktop),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildSelectedView(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar(BuildContext context, bool isDesktop) {
    final displayName = widget.ownerName ?? 'Resort Owner';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'O';

    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            Builder(
              builder: (innerContext) => IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF0F172A)),
                onPressed: () => Scaffold.of(innerContext).openDrawer(),
              ),
            ),
          if (!isDesktop) const SizedBox(width: 4),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getMenuTitle(_selectedMenuIndex),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: isDesktop ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  isDesktop ? 'Aqua Resort Management Console' : 'Owner Console',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // Search Box on Desktop
          if (isDesktop) ...[
            Container(
              width: 240,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search resorts, bookings...',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Notification Bell
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
                  icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF334155), size: 20),
                  onPressed: () {},
                ),
              ),
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F9D94),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: const Text(
                    '2',
                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(width: isDesktop ? 12 : 8),

          // Profile Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF0F9D94).withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFF0F9D94),
                  child: Text(
                    initial,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Verified Owner',
                        style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF0F9D94), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContents(BuildContext context) {
    final displayName = widget.ownerName ?? 'Resort Owner';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'O';

    return Column(
      children: [
        // Brand Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Row(
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
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F9D94).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.villa_rounded, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aqua Resorts',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Owner Control Center',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // Owner Account Info Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF0F9D94),
                child: Text(
                  initial,
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                    Text(
                      'Active Session',
                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF10B981), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Navigation Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            children: [
              _buildSidebarItem(0, Icons.dashboard_rounded, 'Dashboard Overview'),
              _buildSidebarItem(1, Icons.location_on_rounded, 'Resort Locations'),
              _buildSidebarItem(2, Icons.calendar_month_rounded, 'Manage Bookings'),
              _buildSidebarItem(3, Icons.villa_rounded, 'Resort Details'),
              _buildSidebarItem(4, Icons.photo_library_rounded, 'Resort Photo Gallery'),
            ],
          ),
        ),

        // Logout Button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            width: double.infinity,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Logout Session',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String title) {
    final isSelected = _selectedMenuIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: isSelected ? const Color(0xFFF0FDF9) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedMenuIndex = index;
            });
            if (MediaQuery.of(context).size.width < 1100) {
              Navigator.pop(context);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              border: isSelected
                  ? Border(left: BorderSide(color: const Color(0xFF0F9D94), width: 4))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFF0F9D94) : const Color(0xFF64748B),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      color: isSelected ? const Color(0xFF0F9D94) : const Color(0xFF334155),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F9D94),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
