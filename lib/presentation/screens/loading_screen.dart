// lib/presentation/screens/loading_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meal_planner_app/presentation/providers/meal_planner_notifier.dart';
import 'package:meal_planner_app/presentation/screens/home_screen.dart';
import 'package:meal_planner_app/presentation/screens/auth_screen.dart';

/// --- AUTH ROUTER SCREEN ---
/// Checks the authentication state and routes the user accordingly.

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    // Start the auth check process immediately
    _initializeApp();
  }

  void _initializeApp() async {
    final notifier = context.read<MealPlannerNotifier>();

    // Step 1: Initialize Auth Listener.
    // This sets up the listener that automatically checks for a persisted session.
    await notifier.initializeAuth();

    if (!mounted) return;

    // Step 2: Route the user based on the final authentication state.
    if (notifier.isLoggedIn) {
      // User has a valid session (e.g., they logged in previously)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // No valid session found, redirect to the Login/Sign Up UI
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a clean loading indicator while the asynchronous auth check runs.
    return const Scaffold(
      backgroundColor: Colors.teal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
              "Checking user session...",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
