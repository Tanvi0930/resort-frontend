import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'profile_options_screens.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final String userPhone;
  final String userEmail;
  final String userRole;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.userEmail,
    this.userRole = '1',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Curved Header
            _buildHeader(),
            
            const SizedBox(height: 16),
            
            // Menu Items
            _buildMenuItems(),
            
            const SizedBox(height: 24),
            
            // Logout Button
            _buildLogoutButton(context),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String roleLabel = 'Regular User';
    Color roleColor = const Color(0xFF3E7C59);
    switch (userRole) {
      case '2':
        roleLabel = 'System Admin';
        roleColor = const Color(0xFF5A93E5);
        break;
      case '3':
        roleLabel = 'Resort Owner';
        roleColor = const Color(0xFFE5A93C);
        break;
      case '4':
        roleLabel = 'Ticket Scanner';
        roleColor = const Color(0xFFE57373);
        break;
    }

    return Container(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 40),
      decoration: const BoxDecoration(
        color: Color(0xFFE8F3EB), // Soft green background
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFF3E7C59),
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
          ),
          const SizedBox(width: 20),
          
          // User Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A2B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userPhone,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    roleLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: roleColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Premium Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5E8DB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspace_premium, color: Color(0xFFDAA520), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Premium Member',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3E7C59).withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Settings Icon in Header
          const Align(
            alignment: Alignment.topRight,
            child: Icon(Icons.settings_outlined, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Builder(
        builder: (context) => Column(
          children: [
            _buildMenuItem(context, Icons.person_outline, 'My Profile', MyProfileScreen(
              userId: userId,
              userName: userName,
              userPhone: userPhone,
              userEmail: userEmail,
            )),
            _buildMenuItem(context, Icons.calendar_today_outlined, 'My Bookings', const MyBookingsScreen()),
            _buildMenuItem(context, Icons.favorite_outline, 'My Favorites', const MyFavoritesScreen()),
            _buildMenuItem(context, Icons.payment_outlined, 'Payment Methods', const PaymentMethodsScreen()),
            _buildMenuItem(context, Icons.location_on_outlined, 'Address Book', const AddressBookScreen()),
            _buildMenuItem(context, Icons.notifications_none_outlined, 'Notifications', const NotificationsScreen()),
            _buildMenuItem(context, Icons.help_outline, 'Help & Support', const HelpSupportScreen()),
            _buildMenuItem(context, Icons.settings_outlined, 'Settings', const SettingsScreen()),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, Widget destination) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black38),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () async {
            await AuthService.clearSession();
            if (!context.mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
          icon: const Icon(Icons.logout, color: Color(0xFFE57373)),
          label: const Text(
            'Logout',
            style: TextStyle(
              color: Color(0xFFE57373),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFDECEA), // Light orange/red background
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
