import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../api_configue.dart';
import 'owner_dashboard_view.dart';
import 'owner_resort_details_view.dart';
import '../admin/admin_locations_view.dart';
import '../admin/admin_bookings_view.dart';
import '../login_screen.dart';

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
  // 0=Dashboard, 1=Location, 2=Bookings, 3=Resort Details
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

    _activities = [
      {
        'title': 'New booking received: Ocean Paradise Resort',
        'time': '10:30 AM',
        'icon': Icons.calendar_today_outlined,
        'color': const Color(0xFF3E7C59),
      },
      {
        'title': 'Resort details updated: Mountain View Resort',
        'time': '09:15 AM',
        'icon': Icons.edit_outlined,
        'color': const Color(0xFFE5A93C),
      },
      {
        'title': 'Payment received from Aryan Mehta',
        'time': 'Yesterday',
        'icon': Icons.payment_outlined,
        'color': const Color(0xFF3E7C59),
      },
      {
        'title': 'Review added for Ocean Paradise Resort',
        'time': 'Yesterday',
        'icon': Icons.star_border,
        'color': const Color(0xFFE5A93C),
      },
      {
        'title': 'Room availability updated',
        'time': '21 May 2025',
        'icon': Icons.bed_outlined,
        'color': const Color(0xFF5A93E5),
      },
    ];

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
        setState(() {
          _resorts = data.map((item) {
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
        });
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
        setState(() {
          _bookings = data.map((item) {
            return {
              'id': (item['id'] ?? '').toString(),
              'resortName': item['resortName'] ?? '',
              'guestName': item['guestName'] ?? '',
              'date': item['date'] ?? '',
              'status': item['status'] ?? 'Pending',
              'amount': item['amount'] ?? 0.0,
            };
          }).toList();
        });
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
        Icons.add_business_outlined, const Color(0xFF3E7C59));
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
        const Color(0xFF3E7C59));
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
        const Color(0xFF3E7C59));
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
          onResortAdded: _handleResortAdded,
          onResortUpdated: _handleResortUpdated,
          onResortDeleted: _handleResortDeleted,
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
                      color: Color(0xFF1E3A2B))),
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
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            Builder(
              builder: (innerContext) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black87),
                onPressed: () => Scaffold.of(innerContext).openDrawer(),
              ),
            ),
          if (!isDesktop) const SizedBox(width: 8),

          Text(
            _getMenuTitle(_selectedMenuIndex),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A2B),
            ),
          ),

          const Spacer(),

          // Search Box
          if (isDesktop)
            Container(
              width: 280,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F5F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search here...',
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                  prefixIcon:
                      Icon(Icons.search, size: 18, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),

          const SizedBox(width: 20),

          // Notification Bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.black87),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE57373),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Profile Info
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?q=80&w=150&auto=format&fit=crop'),
              ),
              const SizedBox(width: 8),
              if (isDesktop)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.ownerName ?? 'Owner',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A2B),
                      ),
                    ),
                    const Text(
                      'Resort Owner',
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContents(BuildContext context) {
    return Column(
      children: [
        // Logo Header
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.villa_outlined,
                  color: Color(0xFF3E7C59),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Owner Panel',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A2B),
                    ),
                  ),
                  Text(
                    'Welcome, ${widget.ownerName ?? 'Owner'}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Navigation Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              _buildSidebarItem(0, Icons.dashboard_outlined, 'Dashboard'),
              _buildSidebarItem(
                  1, Icons.location_on_outlined, 'Location'),
              _buildSidebarItem(
                  2, Icons.calendar_today_outlined, 'Bookings'),
              _buildSidebarItem(
                  3, Icons.villa_outlined, 'Resort Details'),
            ],
          ),
        ),

        // Logout
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFDECEA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LoginScreen()),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout,
                      color: Color(0xFFE57373), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Logout',
                    style: TextStyle(
                      color: Color(0xFFE57373),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Container(
        decoration: BoxDecoration(
          color:
              isSelected ? const Color(0xFFE8F3EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          onTap: () {
            setState(() {
              _selectedMenuIndex = index;
            });
            if (Scaffold.of(context).isDrawerOpen) {
              Navigator.pop(context);
            }
          },
          dense: true,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          leading: Icon(
            icon,
            color: isSelected
                ? const Color(0xFF3E7C59)
                : Colors.grey.shade600,
            size: 20,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF1E3A2B)
                  : Colors.grey.shade700,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13.5,
            ),
          ),
          // Active indicator dot
          trailing: isSelected
              ? Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3E7C59),
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
