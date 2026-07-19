import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

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
        fontFamily: 'Inter', // Placeholder for custom font
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
