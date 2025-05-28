import 'package:Spendly/auth/screens/onboarding_screen.dart';
import 'package:Spendly/auth/screens/splash_screen.dart';
import 'package:Spendly/home/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show splash while checking auth status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // If logged in → go to HomeScreen
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // If not logged in → go to Onboarding/Login
        return const OnboardingScreen();
      },
    );
  }
}
