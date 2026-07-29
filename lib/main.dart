import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/admin/admin_panel_screen.dart';
import 'screens/owner/owner_panel_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const ResortApp());
}

class ResortApp extends StatelessWidget {
  const ResortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resort Hub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3E7C59)),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const SplashRouter(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final session = await AuthService.getSession();
    if (!mounted) return;
    if (session == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    final role = session['role'] ?? '1';
    if (role == '2') {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => AdminPanelScreen(adminName: session['name']!, adminRole: role),
      ));
    } else if (role == '3') {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => OwnerPanelScreen(ownerName: session['name']!, ownerRole: role),
      ));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => MainScreen(
          userId:    session['userId']!,
          userName:  session['name']!,
          userPhone: session['phone']!,
          userEmail: session['email']!,
          userRole:  role,
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator(color: Color(0xFF2E7D52))),
    );
  }
}
