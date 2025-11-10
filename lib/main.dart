// lib/main.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// NEW RTDB IMPORT
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:meal_planner_app/presentation/providers/meal_planner_notifier.dart';
import 'package:meal_planner_app/presentation/screens/loading_screen.dart';
import 'package:meal_planner_app/data/datasources/meal_remote_datasource.dart';
import 'package:meal_planner_app/data/repositories/meal_repository_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final FirebaseAuth auth = FirebaseAuth.instance;
  // NEW: Get the Realtime Database instance
  final FirebaseDatabase database = FirebaseDatabase.instance;

  final remoteDataSource = MealRemoteDataSource();

  // The repository now needs the RTDB instance
  final repository = MealRepositoryImpl(remoteDataSource, database: database);

  runApp(
    ChangeNotifierProvider(
      // The Notifier receives the Auth and RTDB instances
      create: (context) => MealPlannerNotifier(
        repository,
        auth: auth,
        database: database, // Pass RTDB instance
      ),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  // ... (The rest of MainApp is unchanged)
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meal Planner Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.teal.shade700,
        primarySwatch: Colors.teal,
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
