import 'dart:async';
import 'package:flutter/material.dart';
import 'package:idris_academy/main.dart'; // To access AppRoot

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  @override
  void initState() {
    super.initState();
    // Navigate to the main app after a 3-second delay.
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AppRoot()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // This Scaffold now displays your simple logo centered on a white background.
    // This creates a seamless transition from the native splash screen.
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset('assets/icon/idris_academy_logo.png'),
      ),
    );
  }
}
