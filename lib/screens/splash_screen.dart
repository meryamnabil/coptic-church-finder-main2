import 'package:flutter/material.dart';
import 'dart:async';
import 'home_screen.dart';

const Color primaryGold = Color(0xFFB8965E);
const Color darkGold = Color(0xFF8C6A3E);
const Color backgroundBeige = Color(0xFFF5EFE6);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    animation = CurvedAnimation(parent: controller, curve: Curves.easeIn);

    controller.forward();

    Timer(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBeige,
      body: Center(
        child: FadeTransition(
          opacity: animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// LOGO
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .2),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Image.asset("assets/images/Logo.png", width: 200),
              ),

              const SizedBox(height: 40),

              /// TITLE
              const Text(
                "Coptic Church Finder",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: darkGold,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Find Churches Near You",
                style: TextStyle(fontSize: 16, color: primaryGold),
              ),

              const SizedBox(height: 40),

              /// LOADING
              const CircularProgressIndicator(
                color: primaryGold,
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
