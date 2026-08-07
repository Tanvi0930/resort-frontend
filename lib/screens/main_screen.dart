import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'explore_tab.dart';
import 'bookings_tab.dart';
import 'wishlist_tab.dart';

class MainScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userPhone;
  final String userEmail;
  final String userRole;
  final bool isGuest;
  final int initialTab;

  const MainScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.userEmail,
    this.userRole = '1',
    this.isGuest = false,
    this.initialTab = 0,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
  }

  Widget _buildCurrentScreen() {
    if (widget.userRole == '4') {
      switch (_selectedIndex) {
        case 0:
          return HomeScreen(userName: widget.userName);
        case 1:
          return const TicketScannerTab();
        case 2:
          return ProfileScreen(
            userId: widget.userId,
            userName: widget.userName,
            userPhone: widget.userPhone,
            userEmail: widget.userEmail,
            userRole: widget.userRole,
          );
        default:
          return HomeScreen(userName: widget.userName);
      }
    } else {
      switch (_selectedIndex) {
        case 0:
          return HomeScreen(userName: widget.userName);
        case 1:
          return ExploreTab(userName: widget.userName);
        case 2:
          return BookingsTab(userName: widget.userName);
        case 3:
          return WishlistTab(userName: widget.userName);
        case 4:
          return ProfileScreen(
            userId: widget.userId,
            userName: widget.userName,
            userPhone: widget.userPhone,
            userEmail: widget.userEmail,
            userRole: widget.userRole,
          );
        default:
          return HomeScreen(userName: widget.userName);
      }
    }
  }

  void _onItemTapped(int index) {
    if (widget.userRole == '4') {
      if (widget.isGuest && index == 2) {
        _showGuestLoginPrompt();
        return;
      }
    } else {
      // Guest users can browse (home, explore) but not book, wishlist or view profile
      if (widget.isGuest && (index == 2 || index == 3 || index == 4)) {
        _showGuestLoginPrompt();
        return;
      }
    }
    setState(() => _selectedIndex = index);
  }

  void _showGuestLoginPrompt() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Icon(Icons.lock_outline, size: 40, color: Color(0xFF243B53)),
            const SizedBox(height: 12),
            const Text('Sign in Required', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
            const SizedBox(height: 8),
            Text('Please sign in or create an account to make bookings and access your profile.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(context, MaterialPageRoute(
                    builder: (_) => const LoginScreen(guestMode: true),
                  ));
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF243B53), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Sign In', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                },
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF243B53), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Create Account', style: TextStyle(color: Color(0xFF243B53), fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBottomNavItems() {
    final activeColor = const Color(0xFF0F9D94);
    final inactiveColor = const Color(0xFF6F8D8B);
    
    if (widget.userRole == '4') {
      final List<Map<String, dynamic>> items = [
        {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Home'},
        {'icon': Icons.qr_code_scanner_outlined, 'activeIcon': Icons.qr_code_scanner, 'label': 'Scan Tickets'},
        {'icon': Icons.person_outline, 'activeIcon': Icons.person, 'label': 'Profile'},
      ];
      return items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isSelected = _selectedIndex == index;
        return _buildNavButton(index, item, isSelected, activeColor, inactiveColor);
      }).toList();
    } else {
      final List<Map<String, dynamic>> items = [
        {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Home'},
        {'icon': Icons.explore_outlined, 'activeIcon': Icons.explore, 'label': 'Explore'},
        {'icon': Icons.calendar_today_outlined, 'activeIcon': Icons.calendar_today, 'label': 'Bookings'},
        {'icon': Icons.favorite_border, 'activeIcon': Icons.favorite, 'label': 'Wishlist', 'badge': 2},
        {'icon': Icons.person_outline, 'activeIcon': Icons.person, 'label': 'Profile'},
      ];
      return items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isSelected = _selectedIndex == index;
        return _buildNavButton(index, item, isSelected, activeColor, inactiveColor);
      }).toList();
    }
  }

  Widget _buildNavButton(int index, Map<String, dynamic> item, bool isSelected, Color activeColor, Color inactiveColor) {
    Widget iconWidget = Icon(
      isSelected ? item['activeIcon'] : item['icon'],
      color: isSelected ? activeColor : inactiveColor,
      size: 24,
    );
    
    if (item['badge'] != null && item['badge'] > 0) {
      iconWidget = Badge(
        label: Text('${item['badge']}', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red,
        child: iconWidget,
      );
    }

    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(height: 2),
            Text(
              item['label'],
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ] else ...[
              const SizedBox(height: 9),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(),
      bottomNavigationBar: Container(
        height: 75,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _buildBottomNavItems(),
          ),
        ),
      ),
    );
  }
}

class TicketScannerTab extends StatefulWidget {
  const TicketScannerTab({super.key});

  @override
  State<TicketScannerTab> createState() => _TicketScannerTabState();
}

class _TicketScannerTabState extends State<TicketScannerTab> {
  final _ticketIdController = TextEditingController();
  bool _isValidating = false;
  String? _validationResult;
  bool _isValid = false;

  void _validateTicket() {
    final ticketId = _ticketIdController.text.trim();
    if (ticketId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Booking or Ticket ID')),
      );
      return;
    }

    setState(() {
      _isValidating = true;
      _validationResult = null;
    });

    // Simulate database lookup
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _isValidating = false;
        if (ticketId.toUpperCase().startsWith('B')) {
          _isValid = true;
          _validationResult = 'Ticket Valid!\nGuest: John Doe\nResort: Ocean Paradise Resort\nStatus: Confirmed';
        } else {
          _isValid = false;
          _validationResult = 'Invalid Ticket ID\nNo booking found or ticket already scanned.';
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.qr_code_scanner, size: 80, color: Color(0xFF0F9D94)),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter Booking / Ticket ID to Verify Guest Check-In',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _ticketIdController,
                    decoration: const InputDecoration(
                      labelText: 'Booking / Ticket ID (e.g. B342)',
                      prefixIcon: Icon(Icons.vpn_key_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _validateTicket,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F9D94),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isValidating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Verify Ticket', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),
                  if (_validationResult != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isValid ? const Color(0xFFE6F4F1) : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _isValid ? const Color(0xFF0F9D94) : Colors.red.shade200),
                      ),
                      child: Text(
                        _validationResult!,
                        style: TextStyle(
                          color: _isValid ? const Color(0xFF0F9D94) : Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
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
                    child: const Center(
                      child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Staff Access',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const Text(
                        'Ticket Scanner Panel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
        ),
      ),
    );
  }
}
