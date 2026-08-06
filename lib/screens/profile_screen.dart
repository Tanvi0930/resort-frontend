import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'profile_options_screens.dart';

class ProfileScreen extends StatefulWidget {
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
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    final displayName = widget.userName.isNotEmpty ? widget.userName : 'Arjun Sharma';
    final displayEmail = widget.userEmail.isNotEmpty ? widget.userEmail : 'arjun.sharma@email.com';
    final displayPhone = widget.userPhone.isNotEmpty ? widget.userPhone : '+91 98765 43210';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. Top Bar Header (Matching Home/Explore/Bookings/Wishlist)
          _buildHeader(displayName),

          // 2. Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Teal Hero User Card
                  _buildTealUserCard(displayName, displayEmail, displayPhone),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Quick Stats Row (Bookings, Wishlist, Reviews, Cards)
                        _buildQuickStatsCard(),

                        const SizedBox(height: 20),

                        // ACCOUNT Section
                        _buildSectionHeader('ACCOUNT'),
                        _buildCardContainer([
                          _buildListTileItem(
                            icon: Icons.person_outline_rounded,
                            title: 'Personal Information',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MyProfileScreen(
                                    userId: widget.userId,
                                    userName: widget.userName,
                                    userPhone: widget.userPhone,
                                    userEmail: widget.userEmail,
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildDivider(),
                          _buildListTileItem(
                            icon: Icons.edit_outlined,
                            title: 'Edit Profile',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MyProfileScreen(
                                    userId: widget.userId,
                                    userName: widget.userName,
                                    userPhone: widget.userPhone,
                                    userEmail: widget.userEmail,
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildDivider(),
                          _buildListTileItem(
                            icon: Icons.chat_bubble_outline_rounded,
                            title: 'My Reviews',
                            onTap: () {
                              _showToast('My Reviews coming soon!');
                            },
                          ),
                          _buildDivider(),
                          _buildListTileItem(
                            icon: Icons.credit_card_outlined,
                            title: 'Payment Methods',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()),
                              );
                            },
                          ),
                          _buildDivider(),
                          _buildListTileItem(
                            icon: Icons.location_on_outlined,
                            title: 'Saved Addresses',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AddressBookScreen()),
                              );
                            },
                          ),
                        ]),

                        const SizedBox(height: 20),

                        // PREFERENCES Section
                        _buildSectionHeader('PREFERENCES'),
                        _buildCardContainer([
                          _buildListTileItem(
                            icon: Icons.notifications_none_rounded,
                            title: 'Notifications',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                              );
                            },
                          ),
                          _buildDivider(),
                          _buildListTileItem(
                            icon: Icons.language_outlined,
                            title: 'Language & Region',
                            onTap: () {
                              _showToast('Language: English (US)');
                            },
                          ),
                          _buildDivider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE6F4F1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.dark_mode_outlined, color: Color(0xFF0F9D94), size: 20),
                                    ),
                                    const SizedBox(width: 14),
                                    Text(
                                      'Dark Mode',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: _darkModeEnabled,
                                  activeThumbColor: const Color(0xFF0F9D94),
                                  onChanged: (val) {
                                    setState(() {
                                      _darkModeEnabled = val;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ]),

                        const SizedBox(height: 20),

                        // SUPPORT Section
                        _buildSectionHeader('SUPPORT'),
                        _buildCardContainer([
                          _buildListTileItem(
                            icon: Icons.help_outline_rounded,
                            title: 'Help Center',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                              );
                            },
                          ),
                          _buildDivider(),
                          _buildListTileItem(
                            icon: Icons.shield_outlined,
                            title: 'Privacy Policy',
                            onTap: () {
                              _showToast('Privacy Policy opening...');
                            },
                          ),
                          _buildDivider(),
                          _buildListTileItem(
                            icon: Icons.description_outlined,
                            title: 'Terms & Conditions',
                            onTap: () {
                              _showToast('Terms & Conditions opening...');
                            },
                          ),
                          _buildDivider(),
                          _buildListTileItem(
                            icon: Icons.info_outline_rounded,
                            title: 'About App',
                            onTap: () {
                              _showToast('Resort App v2.4.1');
                            },
                          ),
                        ]),

                        const SizedBox(height: 20),

                        // GROW Section
                        _buildSectionHeader('GROW'),
                        _buildCardContainer([
                          _buildListTileItem(
                            icon: Icons.card_giftcard_outlined,
                            title: 'Refer & Earn',
                            onTap: () {
                              _showToast('Refer code: RESORT2025');
                            },
                          ),
                          _buildDivider(),
                          _buildListTileItem(
                            icon: Icons.people_outline_rounded,
                            title: 'Invite Friends',
                            onTap: () {
                              _showToast('Share link copied!');
                            },
                          ),
                        ]),

                        const SizedBox(height: 24),

                        // Log Out Button
                        _buildLogoutButton(context),

                        const SizedBox(height: 16),

                        // Footer Text
                        Center(
                          child: Text(
                            'Resort App v2.4.1 • Made with ❤️ in India',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
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

  Widget _buildHeader(String name) {
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
                        name.isNotEmpty ? name[0].toUpperCase() : 'A',
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
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        'My Profile',
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

  Widget _buildTealUserCard(String name, String email, String phone) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F9D94), Color(0xFF00796B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Avatar Circle with Camera Edit Badge
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'A',
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Name
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            email,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 2),

          // Phone
          Text(
            phone,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 16),

          // Member Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_outlined, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Gold Member',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(Icons.calendar_month_outlined, '12', 'Bookings'),
          _buildStatDivider(),
          _buildStatColumn(Icons.favorite_border_rounded, '8', 'Wishlist'),
          _buildStatDivider(),
          _buildStatColumn(Icons.star_outline_rounded, '24', 'Reviews'),
          _buildStatDivider(),
          _buildStatColumn(Icons.credit_card_outlined, '2', 'Cards'),
        ],
      ),
    );
  }

  Widget _buildStatColumn(IconData icon, String count, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F4F1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF0F9D94), size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 36,
      width: 1,
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF64748B),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTileItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F4F1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF0F9D94), size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF1F5F9),
      indent: 56,
      endIndent: 16,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
      ),
      child: InkWell(
        onTap: () async {
          await AuthService.clearSession();
          if (!context.mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
            const SizedBox(width: 8),
            Text(
              'Log Out',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }
}
