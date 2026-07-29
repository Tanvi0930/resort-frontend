import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_configue.dart';
import '../utils/toast.dart';
import '../services/auth_service.dart';
import 'main_screen.dart';
import 'register_screen.dart';
import 'admin/admin_panel_screen.dart';
import 'owner/owner_panel_screen.dart';
import 'otp_boxes.dart';

class LoginScreen extends StatefulWidget {
  final bool guestMode; // if true, came from guest → booking prompt
  const LoginScreen({super.key, this.guestMode = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpBoxKey = GlobalKey<OtpBoxesState>();
  String _otpValue = '';
  bool _otpSent = false;
  bool _isLoading = false;

  static const _green = Color(0xFF2E7D52);

  String get _baseUrl => ApiConfigue.baseUrl.replaceAll(' ', '');

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length != 10) {
      AppToast.show(context, 'Please enter a valid 10-digit mobile number', type: ToastType.warning);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/otp/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': phone}),
      );
      if (res.statusCode == 200) {
        setState(() => _otpSent = true);
        AppToast.show(context, 'OTP sent! Check server console for the code.', type: ToastType.success);
      } else {
        AppToast.show(context, jsonDecode(res.body)['message'] ?? 'Failed to send OTP', type: ToastType.error);
      }
    } catch (e) {
      AppToast.show(context, 'Error connecting to server: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp([String? autoOtp]) async {
    final phone = _phoneController.text.trim();
    final otp = autoOtp ?? _otpValue;
    if (otp.length != 4) { AppToast.show(context, 'Please enter the 4-digit OTP', type: ToastType.warning); return; }
    setState(() => _isLoading = true);
    try {
      final verifyRes = await http.post(
        Uri.parse('$_baseUrl/api/otp/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': phone, 'otp': otp}),
      );
      if (verifyRes.statusCode != 200) {
        _otpBoxKey.currentState?.recordFailedAttempt();
        AppToast.show(context, jsonDecode(verifyRes.body)['message'] ?? 'Invalid OTP', type: ToastType.error);
        return;
      }
      final loginRes = await http.post(
        Uri.parse('$_baseUrl/api/auth/login-by-phone'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );
      if (loginRes.statusCode == 200) {
        final body = jsonDecode(loginRes.body);
        final String role = (body['role'] ?? '1').toString();
        await AuthService.saveSession(
          token:  body['token'] ?? '',
          userId: body['userId'].toString(),
          name:   body['name'] ?? 'User',
          phone:  phone,
          email:  body['email'] ?? 'Not Provided',
          role:   role,
        );
        if (!mounted) return;
        if (role == '2') {
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => AdminPanelScreen(adminName: body['name'] ?? 'Admin', adminRole: role),
          ));
        } else if (role == '3') {
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => OwnerPanelScreen(ownerName: body['name'] ?? 'Owner', ownerRole: role),
          ));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => MainScreen(
              userId: body['userId'].toString(),
              userName: body['name'] ?? 'User',
              userPhone: phone,
              userEmail: body['email'] ?? 'Not Provided',
              userRole: role,
            ),
          ));
        }
      } else if (loginRes.statusCode == 404) {
        AppToast.show(context, 'User not found. Please register first.', type: ToastType.warning);
        if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
      } else {
        AppToast.show(context, jsonDecode(loginRes.body)['message'] ?? 'Login failed', type: ToastType.error);
      }
    } catch (e) {
      AppToast.show(context, 'Error connecting to server: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _continueAsGuest() {
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => const MainScreen(
        userId: '',
        userName: 'Guest',
        userPhone: '',
        userEmail: '',
        userRole: '0',
        isGuest: true,
      ),
    ));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          reverse: true,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero ──
            Stack(
              children: [
                Container(
                  height: size.height * 0.38,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1540541338287-41700207dee6?q=80&w=2070&auto=format&fit=crop'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  height: size.height * 0.38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withValues(alpha: 0.1), Colors.black.withValues(alpha: 0.6)],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 32, left: 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.eco, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text('ResortHub', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 6),
                      const Text('Your perfect getaway starts here', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),

            // ── Form ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Guest mode banner
                  if (widget.guestMode) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline, size: 16, color: _green),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Sign in to complete your booking', style: TextStyle(fontSize: 13, color: _green, fontWeight: FontWeight.w500))),
                      ]),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Text(
                    _otpSent ? 'Verify OTP' : 'Welcome back',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _otpSent
                        ? 'Enter the 4-digit code sent to +91 ${_phoneController.text.trim()}'
                        : 'Sign in with your mobile number',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 28),

                  if (!_otpSent) ...[
                    _label('Mobile Number'),
                    const SizedBox(height: 8),
                    _phoneField(),
                    const SizedBox(height: 24),
                    _primaryButton('Send OTP', _isLoading ? null : _sendOtp, _isLoading),
                  ],

                  if (_otpSent) ...[
                    OtpBoxes(
                      key: _otpBoxKey,
                      enabled: !_isLoading,
                      maxAttempts: 3,
                      resendSeconds: 30,
                      onCompleted: (otp) { _otpValue = otp; _verifyOtp(otp); },
                      onResend: _sendOtp,
                    ),
                    const SizedBox(height: 24),
                    _primaryButton('Verify & Login', _isLoading ? null : _verifyOtp, _isLoading),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: _isLoading ? null : () => setState(() { _otpSent = false; _otpValue = ''; }),
                        child: const Text('← Change Number', style: TextStyle(color: _green, fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),
                  Row(children: [
                    Expanded(child: Divider(color: Colors.grey.shade200)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade200)),
                  ]),
                  const SizedBox(height: 16),

                  // Guest Mode
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _continueAsGuest,
                      icon: const Icon(Icons.person_outline, size: 18),
                      label: const Text('Continue as Guest', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Register
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _green, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Create an Account', style: TextStyle(color: _green, fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)));

  Widget _phoneField() => TextField(
    controller: _phoneController,
    keyboardType: TextInputType.phone,
    maxLength: 10,
    enabled: !_otpSent,
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
    decoration: InputDecoration(
      counterText: '',
      hintText: 'Enter 10-digit number',
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('+91', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          const SizedBox(width: 8),
          Container(width: 1, height: 20, color: Colors.grey.shade300),
        ]),
      ),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: _green, width: 1.5)),
      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade100)),
    ),
  );

  Widget _primaryButton(String label, VoidCallback? onPressed, bool loading) => SizedBox(
    width: double.infinity,
    height: 54,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _green,
        disabledBackgroundColor: _green.withValues(alpha: 0.6),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: loading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
          : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
    ),
  );
}
