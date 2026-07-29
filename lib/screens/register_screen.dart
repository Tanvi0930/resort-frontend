import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_configue.dart';
import '../utils/toast.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'otp_boxes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpBoxKey = GlobalKey<OtpBoxesState>();
  String _otpValue = '';
  String? _selectedGender;
  bool _agreeToTerms = false;
  bool _otpSent = false;
  bool _isLoading = false;

  static const _green = Color(0xFF2E7D52);

  String get _baseUrl => ApiConfigue.baseUrl.replaceAll(' ', '');

  Future<void> _sendOtp() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty) { AppToast.show(context, 'Please enter your full name', type: ToastType.warning); return; }
    if (_selectedGender == null) { AppToast.show(context, 'Please select your gender', type: ToastType.warning); return; }
    if (phone.length != 10) { AppToast.show(context, 'Phone number must be exactly 10 digits', type: ToastType.warning); return; }
    if (!_agreeToTerms) { AppToast.show(context, 'Please agree to the Terms & Conditions', type: ToastType.warning); return; }

    setState(() => _isLoading = true);
    try {
      final checkRes = await http.get(Uri.parse('$_baseUrl/api/auth/users'));
      if (checkRes.statusCode == 200) {
        final users = jsonDecode(checkRes.body) as List;
        if (users.any((u) => u['emailOrPhone'] == phone)) {
          AppToast.show(context, 'User already exists. Please login.', type: ToastType.warning);
          return;
        }
      }
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

  Future<void> _verifyAndRegister([String? autoOtp]) async {
    final otp = autoOtp ?? _otpValue;
    final phone = _phoneController.text.trim();
    if (otp.length != 6) { AppToast.show(context, 'Please enter the 6-digit OTP', type: ToastType.warning); return; }

    setState(() => _isLoading = true);
    try {
      final verifyRes = await http.post(
        Uri.parse('$_baseUrl/api/otp/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': phone, 'otp': otp}),
      );
      if (verifyRes.statusCode != 200) {
        _otpBoxKey.currentState?.recordFailedAttempt();
        AppToast.show(context, jsonDecode(verifyRes.body)['message'] ?? 'OTP verification failed', type: ToastType.error);
        return;
      }
      final registerRes = await http.post(
        Uri.parse('$_baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'emailOrPhone': phone,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'gender': _selectedGender,
        }),
      );
      if (registerRes.statusCode == 201) {
        final loginRes = await http.post(
          Uri.parse('$_baseUrl/api/auth/login-by-phone'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone}),
        );
        if (loginRes.statusCode == 200 && mounted) {
          final body = jsonDecode(loginRes.body);
          await AuthService.saveSession(
            token:  body['token'] ?? '',
            userId: body['userId'].toString(),
            name:   body['name'] ?? 'User',
            phone:  phone,
            email:  body['email'] ?? 'Not Provided',
            role:   body['role']?.toString() ?? '1',
          );
          if (!mounted) return;
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => MainScreen(
              userId: body['userId'].toString(),
              userName: body['name'] ?? 'User',
              userPhone: phone,
              userEmail: body['email'] ?? 'Not Provided',
              userRole: body['role']?.toString() ?? '1',
            ),
          ));
        }
      } else {
        AppToast.show(context, jsonDecode(registerRes.body)['message'] ?? 'Registration failed', type: ToastType.error);
      }
    } catch (e) {
      AppToast.show(context, 'Error connecting to server: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A2B))),
        content: const SingleChildScrollView(
          child: Text(
            '1. Acceptance\nBy registering, you agree to these terms.\n\n'
            '2. Account\nYou are responsible for keeping your account secure. Provide accurate information during registration.\n\n'
            '3. Use of Service\nUse the app only for lawful purposes. Do not misuse or attempt to disrupt the service.\n\n'
            '4. Bookings\nAll bookings are subject to availability. Cancellation policies apply as stated at the time of booking.\n\n'
            '5. Privacy\nYour personal data is collected and used solely to provide our services. We do not sell your data to third parties.\n\n'
            '6. Changes\nWe reserve the right to update these terms at any time. Continued use of the app implies acceptance.',
            style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.6),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () { setState(() => _agreeToTerms = true); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: _green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('I Agree', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── Top Bar ──
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF374151)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Header ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.eco, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text('ResortHub', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                _otpSent ? 'Verify your number' : 'Create account',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 6),
              Text(
                _otpSent
                    ? 'Enter the 6-digit code sent to +91 ${_phoneController.text.trim()}'
                    : 'Join us and explore amazing resorts',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              if (!_otpSent) ...[
                // ── Step 1: Details ──
                _label('Full Name'),
                const SizedBox(height: 8),
                _inputField(controller: _nameController, hint: 'Enter your full name', icon: Icons.person_outline),
                const SizedBox(height: 20),

                _label('Email Address'),
                const SizedBox(height: 8),
                _inputField(controller: _emailController, hint: 'Enter email (optional)', icon: Icons.mail_outline, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 20),

                _label('Mobile Number'),
                const SizedBox(height: 8),
                _phoneField(),
                const SizedBox(height: 20),

                _label('Gender'),
                const SizedBox(height: 10),
                _genderSelector(),
                const SizedBox(height: 24),

                // ── Terms ──
                GestureDetector(
                  onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: _agreeToTerms ? _green : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _agreeToTerms ? _green : Colors.grey.shade300, width: 1.5),
                        ),
                        child: _agreeToTerms ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: _showTermsDialog,
                          child: RichText(
                            text: TextSpan(
                              text: 'I agree to the ',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                              children: const [
                                TextSpan(
                                  text: 'Terms & Conditions',
                                  style: TextStyle(color: _green, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _primaryButton('Send OTP', _isLoading ? null : _sendOtp, _isLoading),
              ],

              if (_otpSent) ...[
                // ── Step 2: OTP ──
                OtpBoxes(
                  key: _otpBoxKey,
                  enabled: !_isLoading,
                  maxAttempts: 3,
                  resendSeconds: 30,
                  onCompleted: (otp) { _otpValue = otp; _verifyAndRegister(otp); },
                  onResend: _sendOtp,
                ),
                const SizedBox(height: 28),
                _primaryButton('Verify & Register', _isLoading ? null : _verifyAndRegister, _isLoading),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => setState(() { _otpSent = false; _otpValue = ''; }),
                    child: const Text('← Change Details', style: TextStyle(color: _green, fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ),
              ],

              const SizedBox(height: 32),
              Row(children: [
                Expanded(child: Divider(color: Colors.grey.shade200)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Already have an account?', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ),
                Expanded(child: Divider(color: Colors.grey.shade200)),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _green, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Sign In', style: TextStyle(color: _green, fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)));

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      enabled: enabled,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _green, width: 1.5)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade100)),
      ),
    );
  }

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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('+91', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(width: 8),
            Container(width: 1, height: 20, color: Colors.grey.shade300),
          ],
        ),
      ),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _green, width: 1.5)),
      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade100)),
    ),
  );

  Widget _genderSelector() {
    return Row(
      children: ['Male', 'Female', 'Other'].map((g) {
        final selected = _selectedGender == g;
        return Expanded(
          child: GestureDetector(
            onTap: _otpSent ? null : () => setState(() => _selectedGender = g),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: selected ? _green : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? _green : Colors.grey.shade200, width: 1.5),
              ),
              child: Text(
                g,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.grey.shade600),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

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
          : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.3)),
    ),
  );
}
