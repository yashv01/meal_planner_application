// lib/domain/repositories/meal_repository.dart

import '../entities/meal_plan.dart';

/// --- DOMAIN LAYER: REPOSITORIES (CONTRACTS) ---
/// This interface defines the expected behavior from the data layer. 
/// It's the "what," not the "how."

abstract class MealRepository {
  /// Fetches a list of meals based on user inputs for local assembly.
  Future<List<Meal>> fetchMealsForPlanning({
    required String dietType,
    required List<String> restrictions,
  });

  /// Fetches the full detailed recipe for a specific meal ID.
  Future<Meal> getMealDetails(Meal meal);

  // V1 In-memory storage methods
  Future<void> savePlan(MealPlan plan);
  Future<List<MealPlan>> getSavedPlans();
}