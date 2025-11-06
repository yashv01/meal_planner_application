// lib/main.dart

import 'package:flutter/material.dart';
import 'package:meal_planner_app/presentation/providers/meal_planner_notifier.dart';
import 'package:meal_planner_app/presentation/screens/loading_screen.dart';
import 'package:provider/provider.dart';
import 'package:meal_planner_app/data/datasources/meal_remote_datasource.dart';
import 'package:meal_planner_app/data/repositories/meal_repository_impl.dart';

void main() {
  // --- REAL DATA LAYER INITIALIZATION ---
  // 1. Instantiate the DataSource (API client)
  final remoteDataSource = MealRemoteDataSource();
  // 2. Instantiate the Repository (logic) using the DataSource
  final repository = MealRepositoryImpl(remoteDataSource);

  runApp(
    ChangeNotifierProvider(
      // The Notifier now uses the REAL repository
      create: (context) => MealPlannerNotifier(repository),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meal Planner Pro',
      // --- PROFESSIONAL THEME DEFINITION ---
      theme: ThemeData(
        primaryColor: Colors.teal.shade700,
        primarySwatch: Colors.teal,
        // FIX: Using CardThemeData for correct theming
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter',
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const LoadingScreen(),
    );
  }
}
