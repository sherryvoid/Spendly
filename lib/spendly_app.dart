// lib/app.dart
import 'package:Spendly/auth/screens/forgot_password_screen.dart';
import 'package:Spendly/auth/screens/login_screen.dart';
import 'package:Spendly/auth/screens/onboarding_screen.dart';
import 'package:Spendly/auth/screens/signup_screen.dart';
import 'package:Spendly/auth/screens/splash_screen.dart';
import 'package:Spendly/home/screens/add_expense_screen.dart';
import 'package:Spendly/home/screens/home_screen.dart';
import 'package:Spendly/home/screens/profile_screen.dart';
import 'package:Spendly/home/screens/stats_screen.dart';
import 'package:Spendly/home/screens/wallet_screen.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spendly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.grey[100],
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF5BA29C),
          secondary: const Color(0xFFE064F7),
          tertiary: const Color(0xFFFF8D6C),
          outline: Colors.blueGrey,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/stats': (context) => const StatsScreen(),
        '/wallet': (context) => const WalletScreen(),
        '/expense': (context) => const AddExpenseScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
