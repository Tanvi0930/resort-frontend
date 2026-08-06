import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api_configue.dart';
import 'admin_dashboard_view.dart';
import 'admin_users_view.dart';
import 'admin_locations_view.dart';
import 'admin_bookings_view.dart';
import '../owner/owner_resort_details_view.dart';
import '../login_screen.dart';
import 'admin_extra_modules_views.dart';

class AdminPanelScreen extends StatefulWidget {
  final String? adminName;
  final String? adminRole;

  const AdminPanelScreen({
    super.key,
    this.adminName,
    this.adminRole,
  });

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _selectedMenuIndex = 0;

  // Live Database States
  List<Map<String, dynamic>> _resorts = [];
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _activities = [];

  // Dynamic SharedPreferences-backed States
  List<Map<String, dynamic>> _owners = [];
  List<Map<String, dynamic>> _verifications = [];
  List<Map<String, dynamic>> _coupons = [];
  List<Map<String, dynamic>> _banners = [];
  List<Map<String, dynamic>> _tickets = [];
  List<Map<String, dynamic>> _auditLogs = [];
  List<Map<String, dynamic>> _faqs = [];
  List<Map<String, dynamic>> _notificationsOutbox = [];
  String _termsPolicy = '1. Standard check-in time is 12:00 PM. Check-out is 11:00 AM.\n2. Guests must present valid identification documents upon arrival.';
  String _privacyPolicy = 'We respect privacy principles. Contact information is securely kept and never shared.';
  
  Map<String, dynamic> _systemSettings = {
    'commissionRate': 12.5,
    'taxRate': 5.0,
    'maintenanceMode': false,
    'instantBooking': true,
    'smsOtpLogin': true,
    'refundWindowHours': 48.0
  };

  @override
  void initState() {
    super.initState();
    _loadLocalData();
    _fetchUsersFromBackend();
    _fetchLocationsFromBackend();
    _fetchBookingsFromBackend();
    _fetchResortsFromBackend();
  }

  // --- SharedPreferences Storage Helpers ---
  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _verifications = _decodeList(prefs.getString('admin_verifications'));
      _coupons = _decodeList(prefs.getString('admin_coupons'));
      _banners = _decodeList(prefs.getString('admin_banners'));
      _tickets = _decodeList(prefs.getString('admin_tickets'));
      _auditLogs = _decodeList(prefs.getString('admin_audit_logs'));
      _faqs = _decodeList(prefs.getString('admin_faqs'));
      _notificationsOutbox = _decodeList(prefs.getString('admin_notifications_outbox'));
      _termsPolicy = prefs.getString('admin_terms_policy') ?? _termsPolicy;
      _privacyPolicy = prefs.getString('admin_privacy_policy') ?? _privacyPolicy;

      final settingsStr = prefs.getString('admin_settings');
      if (settingsStr != null) {
        _systemSettings = jsonDecode(settingsStr);
      }
    });
  }

  List<Map<String, dynamic>> _decodeList(String? jsonStr) {
    if (jsonStr == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveLocalList(String key, List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(list));
  }

  // --- Backend Sync Functions ---
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
              'status': item['status'] ?? 'Approved',
              'foodDetails': {
                'veg': item['veg'] ?? false,
                'nonVeg': item['nonVeg'] ?? false,
                'breakfast': item['breakfast'] ?? false,
                'breaksnacks': item['breaksnacks'] ?? false,
              }
            };
          }).toList();
          _updateOwnersList();
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
      final response = await http.get(Uri.parse('$baseUrl/api/locations'));
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

  Future<void> _fetchUsersFromBackend() async {
    try {
      final baseUrl = ApiConfigue.baseUrl.replaceAll(' ', '');
      final response = await http.get(Uri.parse('$baseUrl/api/auth/users'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _users = data.map((item) {
            return {
              'id': (item['id'] ?? '').toString(),
              'name': item['name'] ?? '',
              'email': item['email'] ?? '',
              'phone': item['emailOrPhone'] ?? '',
              'role': item['role'] ?? '1',
              'status': item['status'] ?? 'Active',
              'joinDate': item['joinDate'] ?? '25 Jul 2026',
            };
          }).toList();
          _updateOwnersList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
    }
  }

  // Filter Owners from database Users where role == '3'
  void _updateOwnersList() {
    setState(() {
      _owners = _users.where((u) => u['role'] == '3').map((u) => {
        'id': u['id'],
        'name': u['name'],
        'emailOrPhone': u['phone'],
        'status': u['status'],
        'joinDate': u['joinDate'],
        'resortsCount': _resorts.where((r) => r['email'] == u['email']).length,
        'verified': u['status'] == 'Active',
      }).toList();
    });
  }

  // --- Audit Log Tracker Helper ---
  void _addAuditLog(String action) {
    setState(() {
      _auditLogs.insert(0, {
        'action': action,
        'adminName': widget.adminName ?? 'SuperAdmin',
        'ip': '127.0.0.1',
        'timestamp': DateTime.now().toLocal().toString().split('.')[0],
      });
      _saveLocalList('admin_audit_logs', _auditLogs);
    });
  }

  // --- Callback Event Handlers ---
  Future<void> _handleOwnerAction(String ownerId, String action, String value) async {
    // Find the user entry index that corresponds to the owner id
    final uIdx = _users.indexWhere((u) => u['id'] == ownerId);
    if (uIdx != -1) {
      final updatedUser = Map<String, dynamic>.from(_users[uIdx]);
      if (action == 'verify') {
        updatedUser['status'] = 'Active';
      } else if (action == 'suspend') {
        updatedUser['status'] = 'Suspended';
      } else if (action == 'activate') {
        updatedUser['status'] = 'Active';
      }
      await _handleUserUpdated(uIdx, updatedUser);
      _addAuditLog('$action action applied to Owner ID: $ownerId');
    }
  }

  void _handleVerificationStatus(int id, String status) {
    setState(() {
      final idx = _verifications.indexWhere((v) => v['id'] == id);
      if (idx != -1) {
        _verifications[idx]['status'] = status;
        _saveLocalList('admin_verifications', _verifications);
        _addAuditLog('Verification Case #$id marked as $status');
      }
    });
  }

  void _handleCouponAdded(Map<String, dynamic> coupon) {
    setState(() {
      _coupons.add(coupon);
      _saveLocalList('admin_coupons', _coupons);
      _addAuditLog('Created promotion coupon: ${coupon['code']}');
    });
  }

  void _handleCouponDelete(int id) {
    setState(() {
      _coupons.removeWhere((c) => c['id'] == id);
      _saveLocalList('admin_coupons', _coupons);
      _addAuditLog('Deleted promotion coupon ID: $id');
    });
  }

  void _handleBannerAdded(Map<String, dynamic> banner) {
    setState(() {
      _banners.add(banner);
      _saveLocalList('admin_banners', _banners);
      _addAuditLog('Uploaded marketing banner: ${banner['title']}');
    });
  }

  void _handleBannerDelete(int id) {
    setState(() {
      _banners.removeWhere((b) => b['id'] == id);
      _saveLocalList('admin_banners', _banners);
      _addAuditLog('Deleted banner campaign ID: $id');
    });
  }

  void _handleCommissionSave(double rate) {
    setState(() {
      _systemSettings['commissionRate'] = rate;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('admin_settings', jsonEncode(_systemSettings));
      });
      _addAuditLog('Commission Rate set to $rate%');
    });
  }

  void _handleRefundResult(int refundId, bool approve) {
    setState(() {
      _addAuditLog('Refund decision on Case #$refundId: ${approve ? "Approved" : "Denied"}');
    });
  }

  void _handleSendReply(int ticketId, String text) {
    setState(() {
      final idx = _tickets.indexWhere((t) => t['id'] == ticketId);
      if (idx != -1) {
        _tickets[idx]['replies'].add({'sender': 'Admin', 'text': text, 'date': 'Just Now'});
        _saveLocalList('admin_tickets', _tickets);
        _addAuditLog('Responded to Support ticket #$ticketId');
      }
    });
  }

  void _handleSaveSettings(Map<String, dynamic> settings) {
    setState(() {
      _systemSettings = settings;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('admin_settings', jsonEncode(_systemSettings));
      });
      _addAuditLog('System Configuration settings updated.');
    });
  }

  void _handleFaqAdded(String q, String a) {
    setState(() {
      _faqs.add({'q': q, 'a': a});
      _saveLocalList('admin_faqs', _faqs);
      _addAuditLog('Added FAQ Question: $q');
    });
  }

  void _handleSavePolicies(String terms, String privacy) {
    setState(() {
      _termsPolicy = terms;
      _privacyPolicy = privacy;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('admin_terms_policy', terms);
        prefs.setString('admin_privacy_policy', privacy);
      });
      _addAuditLog('CMS policies terms/privacy document updated.');
    });
  }

  void _handleSendNotification(String title, String body, String audience) {
    setState(() {
      _notificationsOutbox.insert(0, {
        'title': title,
        'body': body,
        'audience': audience,
        'date': DateTime.now().toLocal().toString().split(' ')[0],
      });
      _saveLocalList('admin_notifications_outbox', _notificationsOutbox);
      _addAuditLog('Broadcast announcement pushed to audience: $audience');
    });
  }

  // --- CRUD State Callbacks ---
  Future<void> _handleResortAdded(Map<String, dynamic> resort) async {
    _addAuditLog('New resort added: ${resort['name']}');
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
    _addAuditLog('Resort details updated: ${resort['name']}');
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
    _addAuditLog('Resort deleted: ${rs['name']}');
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

  Future<void> _handleUserAdded(Map<String, dynamic> user) async {
    _addAuditLog('New user account registered: ${user['name']}');
    try {
      final baseUrl = ApiConfigue.baseUrl.replaceAll(' ', '');
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'emailOrPhone': user['phone'],
          'password': 'Password123',
          'name': user['name'],
          'email': user['email'],
          'role': user['role'] ?? '1',
          'status': user['status'] ?? 'Active',
          'joinDate': user['joinDate'],
        }),
      );
      if (response.statusCode == 201) {
        _fetchUsersFromBackend();
      }
    } catch (e) {
      debugPrint('Error adding user: $e');
    }
  }

  Future<void> _handleUserUpdated(int index, Map<String, dynamic> user) async {
    _addAuditLog('User status/details updated: ${user['name']}');
    try {
      final baseUrl = ApiConfigue.baseUrl.replaceAll(' ', '');
      final response = await http.put(
        Uri.parse('$baseUrl/api/auth/profile/edit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': user['id'],
          'name': user['name'],
          'email': user['email'],
          'role': user['role'],
          'status': user['status'],
        }),
      );
      if (response.statusCode == 200) {
        _fetchUsersFromBackend();
      }
    } catch (e) {
      debugPrint('Error updating user: $e');
    }
  }

  Future<void> _handleUserDeleted(int index) async {
    final user = _users[index];
    _addAuditLog('User deleted: ${user['name']}');
    try {
      final baseUrl = ApiConfigue.baseUrl.replaceAll(' ', '');
      final response = await http.delete(
        Uri.parse('$baseUrl/api/auth/users/${user['id']}'),
      );
      if (response.statusCode == 200) {
        _fetchUsersFromBackend();
      }
    } catch (e) {
      debugPrint('Error deleting user: $e');
    }
  }

  Future<void> _handleLocationAdded(Map<String, dynamic> loc) async {
    _addAuditLog('New city location added: ${loc['city']}');
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

  Future<void> _handleLocationUpdated(int index, Map<String, dynamic> loc) async {
    _addAuditLog('Location coordinates modified: ${loc['city']}');
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
    _addAuditLog('Location city deleted: ${loc['city']}');
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

  Future<void> _handleBookingAdded(Map<String, dynamic> bk) async {
    _addAuditLog('Manual booking created for ${bk['guestName']}');
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
    _addAuditLog('Booking details modified: Guest ${bk['guestName']}');
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
    _addAuditLog('Booking removed: Guest ${bk['guestName']}');
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

  // --- Router mapper to Subviews ---
  Widget _buildSelectedView() {
    switch (_selectedMenuIndex) {
      case 0:
        return AdminDashboardView(
          resorts: _resorts,
          users: _users,
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
          users: _users,
          locations: _resorts,
          onBookingAdded: _handleBookingAdded,
          onBookingUpdated: _handleBookingUpdated,
          onBookingDeleted: _handleBookingDeleted,
        );
      case 3:
        return AdminUsersView(
          users: _users,
          bookings: _bookings,
          onUserAdded: _handleUserAdded,
          onUserUpdated: _handleUserUpdated,
          onUserDeleted: _handleUserDeleted,
        );
      case 4:
        return OwnerResortDetailsView(
          resorts: _resorts,
          locations: _locations,
          isAdmin: true,
          onResortAdded: _handleResortAdded,
          onResortUpdated: _handleResortUpdated,
          onResortDeleted: _handleResortDeleted,
        );
      case 5:
        return AdminOwnersView(
          owners: _owners,
          onOwnerAction: _handleOwnerAction,
        );
      case 6:
        return AdminVerificationView(
          verifications: _verifications,
          onStatusChange: _handleVerificationStatus,
        );
      case 7:
        return AdminPromotionsView(
          coupons: _coupons,
          banners: _banners,
          onCouponAdded: _handleCouponAdded,
          onCouponDelete: _handleCouponDelete,
          onBannerAdded: _handleBannerAdded,
          onBannerDelete: _handleBannerDelete,
        );
      case 8:
        return AdminFinancialsView(
          initialCommission: _systemSettings['commissionRate'],
          onCommissionSave: _handleCommissionSave,
          refunds: _bookings.where((b) => b['status'] == 'Cancelled').toList(),
          onRefundResult: _handleRefundResult,
        );
      case 9:
        return AdminContentView(
          faqs: _faqs,
          onAddFaq: _handleFaqAdded,
          terms: _termsPolicy,
          privacy: _privacyPolicy,
          onSavePolicies: _handleSavePolicies,
        );
      case 10:
        return AdminReportsView(
          bookings: _bookings,
        );
      case 11:
        return AdminSupportView(
          tickets: _tickets,
          onSendReply: _handleSendReply,
        );
      case 12:
        return AdminNotificationsView(
          outbox: _notificationsOutbox,
          onSendNotification: _handleSendNotification,
        );
      case 13:
        return AdminSecurityView(
          auditLogs: _auditLogs,
        );
      case 14:
        return AdminSettingsView(
          initialSettings: _systemSettings,
          onSaveSettings: _handleSaveSettings,
        );
      case 15:
        return AdminProfileView(
          adminName: widget.adminName ?? 'System Admin',
          adminRole: widget.adminRole ?? '2',
        );
      default:
        return const Center(child: Text('Under Development'));
    }
  }

  String _getMenuTitle(int index) {
    const Map<int, String> titles = {
      0: 'Dashboard',
      1: 'Locations',
      2: 'Bookings Log',
      3: 'Platform Users',
      4: 'Resorts Audit',
      5: 'Resort Owners',
      6: 'Verification Center',
      7: 'Promo Coupons',
      8: 'Financial Payouts',
      9: 'Content FAQ',
      10: 'System Analytics',
      11: 'Support Tickets',
      12: 'Notification Outbox',
      13: 'Security Matrix',
      14: 'Platform System Settings',
      15: 'Admin Profile',
    };
    return titles[index] ?? 'Dashboard';
  }

  int _getBottomBarIndex(int selectedIndex) {
    switch (selectedIndex) {
      case 0: return 0;
      case 4: return 1;
      case 2: return 2;
      case 3: return 3;
      case 15: return 4;
      default: return 0;
    }
  }

  void _onBottomBarItemTapped(int index) {
    int targetMenuIndex = 0;
    switch (index) {
      case 0: targetMenuIndex = 0; break;
      case 1: targetMenuIndex = 4; break;
      case 2: targetMenuIndex = 2; break;
      case 3: targetMenuIndex = 3; break;
      case 4: targetMenuIndex = 15; break;
    }
    setState(() {
      _selectedMenuIndex = targetMenuIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Row(
          children: [
            // Left Fixed Navigation Sidebar
            SizedBox(
              width: 260,
              child: _buildSidebarNavigation(),
            ),

            // Right Main Content Area
            Expanded(
              child: Column(
                children: [
                  _buildHeaderBar(context),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: KeyedSubtree(
                        key: ValueKey<int>(_selectedMenuIndex),
                        child: _buildSelectedView(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile / Narrow view
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: Drawer(
        child: _buildSidebarNavigation(),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          _getMenuTitle(_selectedMenuIndex),
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF0F172A), fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFF0F172A)),
            onPressed: () => setState(() => _selectedMenuIndex = 12),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedMenuIndex),
          child: _buildSelectedView(),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.12))),
        ),
        child: BottomNavigationBar(
          currentIndex: _getBottomBarIndex(_selectedMenuIndex),
          onTap: _onBottomBarItemTapped,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF4F46E5),
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.holiday_village_outlined),
              activeIcon: Icon(Icons.holiday_village),
              label: 'Resorts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_online_outlined),
              activeIcon: Icon(Icons.book_online),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Guests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarNavigation() {
    final navItems = [
      {'index': 0, 'label': 'Dashboard', 'icon': Icons.dashboard_rounded},
      {'index': 4, 'label': 'Resort Management', 'icon': Icons.holiday_village_rounded},
      {'index': 5, 'label': 'Resort Owners', 'icon': Icons.badge_rounded},
      {'index': 3, 'label': 'User Management', 'icon': Icons.people_alt_rounded},
      {'index': 2, 'label': 'Bookings Log', 'icon': Icons.book_online_rounded},
      {'index': 1, 'label': 'Locations', 'icon': Icons.location_on_rounded},
      {'index': 6, 'label': 'Verifications', 'icon': Icons.verified_user_rounded},
      {'index': 7, 'label': 'Promotions & Coupons', 'icon': Icons.local_offer_rounded},
      {'index': 8, 'label': 'Financial Payouts', 'icon': Icons.payments_rounded},
      {'index': 9, 'label': 'Content & FAQ', 'icon': Icons.article_rounded},
      {'index': 10, 'label': 'System Analytics', 'icon': Icons.insights_rounded},
      {'index': 11, 'label': 'Support Tickets', 'icon': Icons.support_agent_rounded},
      {'index': 12, 'label': 'Notifications', 'icon': Icons.notifications_rounded},
      {'index': 13, 'label': 'Security Matrix', 'icon': Icons.shield_rounded},
      {'index': 14, 'label': 'System Settings', 'icon': Icons.settings_rounded},
      {'index': 15, 'label': 'Admin Profile', 'icon': Icons.account_circle_rounded},
    ];

    return Container(
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          // Logo Branding
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.villa_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RESORT HUB',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      'Admin Control Center',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),

          // Menu List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              itemCount: navItems.length,
              itemBuilder: (context, i) {
                final item = navItems[i];
                final idx = item['index'] as int;
                final isSelected = _selectedMenuIndex == idx;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedMenuIndex = idx);
                        if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                          Navigator.pop(context);
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        child: Row(
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              size: 20,
                              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['label'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Admin Profile Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              border: Border(top: BorderSide(color: Color(0xFF334155), width: 0.5)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF4F46E5),
                  radius: 18,
                  child: Text(
                    (widget.adminName ?? 'A')[0].toUpperCase(),
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.adminName ?? 'System Admin',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Super Administrator',
                        style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Color(0xFFEF4444), size: 18),
                  tooltip: 'Logout',
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar(BuildContext context) {
    final showBackButton = _selectedMenuIndex != 0;

    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.08),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          if (showBackButton) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1E2D27)),
              onPressed: () {
                setState(() {
                  _selectedMenuIndex = 0; // Go back to Dashboard home
                });
              },
              tooltip: 'Back to Dashboard',
            ),
            const SizedBox(width: 8),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F4C43),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.villa, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
          ],

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getMenuTitle(_selectedMenuIndex),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E2D27),
                  ),
                ),
                if (!showBackButton) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Resort Management',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),
          // Bell Icon Container
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1.5),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.notifications_none_outlined, size: 20, color: Color(0xFF1E2D27)),
              onPressed: () {
                setState(() => _selectedMenuIndex = 12);
              },
              tooltip: 'Notifications',
            ),
          ),
          const SizedBox(width: 10),
          // Layout Indicator Grid
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1.5),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.grid_view_outlined, size: 20, color: Color(0xFF1E2D27)),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 10),
          // Logout Container
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1.5),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.logout_outlined, size: 20, color: Colors.redAccent),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              tooltip: 'Logout',
            ),
          ),
        ],
      ),
    );
  }
}
