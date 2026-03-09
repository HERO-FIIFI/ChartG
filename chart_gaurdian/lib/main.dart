import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';
import 'Intropage.dart';
import 'loginpage.dart';
import 'signuppage.dart';
import 'homepage.dart';
import 'services/price_checker_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase not yet configured — app runs with local auth
  }

  // Initialise and start background price alert checker
  final checker = PriceCheckerService();
  await checker.init();
  checker.start();

  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  String initialRoute = '/intro';
  if (hasSeenOnboarding) {
    initialRoute = isLoggedIn ? '/home' : '/login';
  }

  runApp(ChartGuardianApp(initialRoute: initialRoute));
}

class ChartGuardianApp extends StatelessWidget {
  final String initialRoute;

  const ChartGuardianApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Chart Guardian',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _buildRouter(),
    );
  }

  GoRouter _buildRouter() => GoRouter(
        initialLocation: initialRoute,
        routes: [
          GoRoute(
            path: '/intro',
            builder: (context, state) => const IntroPage(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/signup',
            builder: (context, state) => const SignupScreen(),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
        ],
      );
}
