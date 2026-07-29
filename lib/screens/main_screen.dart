import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class MainScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userPhone;
  final String userEmail;
  final String userRole;
  final bool isGuest;

  const MainScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.userEmail,
    this.userRole = '1',
    this.isGuest = false,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;
  late final List<BottomNavigationBarItem> _navItems;

  @override
  void initState() {
    super.initState();
    _initRoleBaseScreens();
  }

  void _initRoleBaseScreens() {
    if (widget.userRole == '4') {
      // Ticket Scanner specific tabs
      _screens = [
        const HomeScreen(),
        const TicketScannerTab(),
        ProfileScreen(
          userId: widget.userId,
          userName: widget.userName,
          userPhone: widget.userPhone,
          userEmail: widget.userEmail,
          userRole: widget.userRole,
        ),
      ];
      _navItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner_outlined),
          activeIcon: Icon(Icons.qr_code_scanner),
          label: 'Scan Tickets',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else {
      // Regular user tabs
      _screens = [
        const HomeScreen(),
        const Center(child: Text('Bookings Screen', style: TextStyle(fontSize: 24))),
        const Center(child: Text('Explore Screen', style: TextStyle(fontSize: 24))),
        ProfileScreen(
          userId: widget.userId,
          userName: widget.userName,
          userPhone: widget.userPhone,
          userEmail: widget.userEmail,
          userRole: widget.userRole,
        ),
      ];
      _navItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: 'Bookings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore_outlined),
          activeIcon: Icon(Icons.explore),
          label: 'Explore',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }
  }

  void _onItemTapped(int index) {
    // Guest users can browse (home, explore) but not book or view profile
    if (widget.isGuest && (index == 1 || index == 3)) {
      _showGuestLoginPrompt();
      return;
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
            const Icon(Icons.lock_outline, size: 40, color: Color(0xFF2E7D52)),
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D52), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF2E7D52), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Create Account', style: TextStyle(color: Color(0xFF2E7D52), fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: const Color(0xFF3E7C59),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: _navItems,
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
      appBar: AppBar(
        title: const Text('Ticket Scanner Panel', style: TextStyle(color: Color(0xFF1E3A2B), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE8F3EB),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.qr_code_scanner, size: 80, color: Color(0xFF3E7C59)),
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
                backgroundColor: const Color(0xFF3E7C59),
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
                  color: _isValid ? const Color(0xFFE8F3EB) : const Color(0xFFFDECEA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isValid ? const Color(0xFF3E7C59) : Colors.redAccent),
                ),
                child: Column(
                  children: [
                    Icon(
                      _isValid ? Icons.check_circle_outline : Icons.error_outline,
                      color: _isValid ? const Color(0xFF3E7C59) : Colors.redAccent,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _validationResult!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _isValid ? const Color(0xFF1E3A2B) : const Color(0xFF8C2D19),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
