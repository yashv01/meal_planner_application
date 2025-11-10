// lib/presentation/providers/meal_planner_notifier.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// USING RTDB
import 'package:firebase_database/firebase_database.dart';
import 'package:meal_planner_app/domain/entities/meal_plan.dart';
import 'package:meal_planner_app/domain/repositories/meal_repository.dart';

class MealPlannerNotifier with ChangeNotifier {
  final MealRepository _repository;
  final FirebaseAuth _auth;
  final FirebaseDatabase _database;

  final Random _random = Random();

  List<MealPlan> _savedPlans = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _userId;
  String _username =
      'Loading...'; // FIX 1: Initialize username to a non-null string

  List<MealPlan> get savedPlans => _savedPlans;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get userId => _userId;
  String get username => _username; // Accessor now returns non-nullable string
  bool get isLoggedIn => _userId != null;

  // Constructor accepts RTDB
  MealPlannerNotifier(
    this._repository, {
    required FirebaseAuth auth,
    required FirebaseDatabase database,
  }) : _auth = auth,
       _database = database; // Constructor initialization list

  // Helper to get the correct RTDB user data path
  DatabaseReference _userDoc(String uid) {
    return _database.ref('user_data').child(uid);
  }

  // Helper to get the correct RTDB meal plan path
  DatabaseReference _planRef() {
    return _database.ref('meal_plans').child(_userId!);
  }

  void clearError() {
    _setError(null);
  }

  // --- AUTHENTICATION & STATE CHANGE LISTENING ---

  Future<void> initializeAuth() async {
    // FIX 2: Check current user immediately and then set up the listener
    await _handleAuthChange(_auth.currentUser);

    // Only set up the listener if it's the first time
    _auth.authStateChanges().listen((user) async {
      await _handleAuthChange(user);
    });
  }

  Future<void> _handleAuthChange(User? user) async {
    _setLoading(true);
    if (user != null) {
      _userId = user.uid;
      await _loadUserData(user.uid);
      await loadSavedPlans();
    } else {
      _userId = null;
      _username = 'Guest'; // Set to non-null default after logout
      _savedPlans = [];
      notifyListeners();
    }
    _setLoading(false);
  }

  // ... (signUp and signIn logic remains the same)

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _userDoc(
        userCredential.user!.uid,
      ).set({'username': username, 'email': email});
      // Listener handles setting _username and navigation
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Sign up failed.');
    } catch (e) {
      _setError('Sign up failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    _setLoading(true);
    _setError(null);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Login failed.');
    } catch (e) {
      _setError('Login failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final snapshot = await _userDoc(uid).get();
      // FIX 3: Ensure value is checked before casting to Map
      _username = (snapshot.value is Map)
          ? (snapshot.value as Map)['username'] ?? 'User'
          : 'User';
      notifyListeners();
    } catch (e) {
      _username = 'User';
      print('Error loading user data: $e');
    }
  }

  Future<void> signOutUser() async {
    _setLoading(true);
    try {
      await _auth.signOut();
      // The auth listener handles setting the final state and clearing data
    } catch (e) {
      _setError('Sign out failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // --- REALTIME DATABASE CRUD OPERATIONS (Unchanged) ---

  @override
  Future<void> loadSavedPlans() async {
    if (_userId == null) return;

    if (!_isLoading) _setLoading(true);
    _setError(null);
    try {
      final snapshot = await _planRef().get();

      _savedPlans = [];
      if (snapshot.value != null && snapshot.value is Map) {
        Map<dynamic, dynamic> plansMap = snapshot.value as Map;

        plansMap.forEach((key, value) {
          List<DayPlan> days =
              (value['days'] as List<dynamic>?)?.map((dayMap) {
                List<Meal> meals =
                    (dayMap['meals'] as List<dynamic>?)?.map((mealMap) {
                      return Meal(
                        type: mealMap['type'] ?? '',
                        name: mealMap['name'] ?? 'Unknown Meal',
                        recipeId: mealMap['recipeId'] ?? '',
                        thumbnailUrl: mealMap['thumbnailUrl'],
                      );
                    }).toList() ??
                    [];
                return DayPlan(
                  day: dayMap['day'] ?? 'Unknown Day',
                  meals: meals,
                );
              }).toList() ??
              [];

          _savedPlans.add(
            MealPlan(
              id: key,
              goal: value['goal'] ?? '',
              dietType: value['dietType'] ?? '',
              creationDate: DateTime.fromMillisecondsSinceEpoch(
                value['creationDate'] ?? 0,
              ),
              days: days,
            ),
          );
        });
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to load saved plans from Realtime Database: $e');
    } finally {
      _setLoading(false);
    }
  }

  @override
  Future<void> generateAndSavePlan({
    required String goal,
    required String dietType,
    required int durationDays,
    required List<String> mealTypes,
    required List<String> restrictions,
  }) async {
    if (_userId == null) {
      _setError('Please sign in to save plans.');
      return;
    }

    _setLoading(true);
    _setError(null);
    try {
      final availableMeals = await _repository.fetchMealsForPlanning(
        dietType: dietType,
        restrictions: restrictions,
      );

      if (availableMeals.isEmpty) {
        throw Exception('No recipes found.');
      }

      final List<DayPlan> generatedDays = _assemblePlan(
        availableMeals,
        durationDays,
        mealTypes,
      );

      final planData = {
        'goal': goal,
        'dietType': dietType,
        'creationDate': DateTime.now().millisecondsSinceEpoch,
        'days': generatedDays
            .map(
              (d) => {
                'day': d.day,
                'meals': d.meals
                    .map(
                      (m) => {
                        'type': m.type,
                        'name': m.name,
                        'recipeId': m.recipeId,
                        'thumbnailUrl': m.thumbnailUrl,
                      },
                    )
                    .toList(),
              },
            )
            .toList(),
      };

      await _planRef().push().set(planData);

      await loadSavedPlans();
    } catch (e) {
      _setError('Plan generation failed. Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  @override
  Future<void> deletePlan(String planId) async {
    if (_userId == null) return;

    _setError(null);
    try {
      await _planRef().child(planId).remove();
      await loadSavedPlans();
    } catch (e) {
      _setError('Failed to delete plan from Realtime Database: $e');
    }
  }

  // --- CORE LOGIC (Unchanged) ---

  List<DayPlan> _assemblePlan(
    List<Meal> availableMeals,
    int durationDays,
    List<String> mealTypes,
  ) {
    final List<DayPlan> generatedPlan = [];
    final List<String> usedMealIds = [];
    final List<String> daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final maxUniqueMeals = availableMeals.length;

    for (int i = 0; i < durationDays; i++) {
      final String currentDay = daysOfWeek[i % 7];
      final List<Meal> dayMeals = [];

      if (i > 0 && i % maxUniqueMeals == 0) {
        usedMealIds.clear();
      }

      for (final mealType in mealTypes) {
        if (availableMeals.isEmpty) continue;

        Meal selectedMeal;
        int attempts = 0;

        do {
          int randomIndex = _random.nextInt(availableMeals.length);
          selectedMeal = availableMeals[randomIndex];
          attempts++;
          if (attempts > 5 * maxUniqueMeals) break;
        } while (usedMealIds.contains(selectedMeal.recipeId));

        if (selectedMeal.recipeId.isNotEmpty) {
          final mealForDay = Meal(
            type: mealType,
            name: selectedMeal.name,
            recipeId: selectedMeal.recipeId,
            thumbnailUrl: selectedMeal.thumbnailUrl,
          );
          dayMeals.add(mealForDay);
          usedMealIds.add(selectedMeal.recipeId);
        }
      }

      generatedPlan.add(DayPlan(day: currentDay, meals: dayMeals));
    }
    return generatedPlan;
  }

  @override
  Future<Meal> getDetailedRecipe(Meal meal) async {
    if (meal.instructions != null && meal.instructions!.isNotEmpty) {
      return meal;
    }

    _setLoading(true);
    try {
      final detailedMeal = await _repository.getMealDetails(meal);
      return detailedMeal;
    } catch (e) {
      _setError('Failed to load recipe details: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading == false) {
      notifyListeners();
    }
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }
}
