// lib/presentation/providers/meal_planner_notifier.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:meal_planner_app/domain/entities/meal_plan.dart';
import 'package:meal_planner_app/domain/repositories/meal_repository.dart';

class MealPlannerNotifier with ChangeNotifier {
  final MealRepository _repository;
  final Random _random = Random();

  List<MealPlan> _savedPlans = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MealPlan> get savedPlans => _savedPlans;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  MealPlannerNotifier(this._repository);

  Future<void> initialize() async {
    // Simulates the time required for initial setup (like Firebase Auth).
    await Future.delayed(const Duration(seconds: 2));
    await loadSavedPlans();
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

  Future<void> loadSavedPlans() async {
    _setLoading(true);
    _setError(null);
    try {
      _savedPlans = await _repository.getSavedPlans();
    } catch (e) {
      _setError('Failed to load saved plans: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> generateAndSavePlan({
    required String goal,
    required String dietType,
    required int durationDays,
    required List<String> mealTypes,
    required List<String> restrictions,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final availableMeals = await _repository.fetchMealsForPlanning(
        dietType: dietType,
        restrictions: restrictions,
      );

      if (availableMeals.isEmpty) {
        throw Exception(
          'No recipes found for the selected diet type: $dietType.',
        );
      }

      final List<DayPlan> generatedDays = _assemblePlan(
        availableMeals,
        durationDays,
        mealTypes,
      );

      final newPlan = MealPlan(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        goal: goal,
        dietType: dietType,
        creationDate: DateTime.now(),
        days: generatedDays,
      );

      await _repository.savePlan(newPlan);
      await loadSavedPlans();
    } catch (e) {
      _setError('Plan generation failed. Error: $e');
    } finally {
      _setLoading(false);
    }
  }

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

  Future<void> deletePlan(String planId) async {
    _setError(null);
    try {
      _savedPlans.removeWhere((plan) => plan.id == planId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete plan: $e');
    }
  }
  
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
}
