import 'package:meal_planner_app/data/datasources/meal_remote_datasource.dart';
import 'package:meal_planner_app/domain/entities/meal_plan.dart';
import 'package:meal_planner_app/domain/repositories/meal_repository.dart';

/// --- DATA LAYER: REPOSITORIES (IMPLEMENTATION) ---
/// This implements the contract from the Domain Layer.
/// It handles data logic, conversion, and persistence (currently in-memory).

class MealRepositoryImpl implements MealRepository {
  final MealRemoteDataSource remoteDataSource;

  // V1 In-memory list to store plans temporarily (Simulated DB)
  final List<MealPlan> _savedPlans = [];

  MealRepositoryImpl(this.remoteDataSource);

  // Helper method to map our simple DietType to TheMealDB's category string
  String _mapDietToCategory(String dietType) {
    if (dietType == 'Vegetarian' || dietType == 'Vegan') return 'Vegetarian';
    if (dietType == 'Seafood') return 'Seafood';
    return 'Chicken'; // Using a common category for 'Standard' and others
  }

  @override
  Future<List<Meal>> fetchMealsForPlanning({
    required String dietType,
    required List<String> restrictions,
  }) async {
    final category = _mapDietToCategory(dietType);
    final rawMeals = await remoteDataSource.fetchMealListByCategory(category);

    // Convert raw JSON list (minimal data) to a list of Meal entities
    return rawMeals
        .map(
          (raw) => Meal(
            type: 'N/A', // Type is set later in the Notifier
            name: raw['strMeal'] ?? 'Unknown Recipe',
            recipeId: raw['idMeal'] ?? '',
            thumbnailUrl: raw['strMealThumb'],
          ),
        )
        .toList();
  }

  @override
  Future<Meal> getMealDetails(Meal meal) async {
    final rawDetails = await remoteDataSource.fetchMealDetailsById(
      meal.recipeId,
    );

    if (rawDetails == null) return meal;

    final instructions =
        rawDetails['strInstructions'] ?? 'No instructions available.';

    // Extract up to 20 ingredients and their measures (TheMealDB structure)
    final List<String> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      final ingredient = rawDetails['strIngredient$i'];
      final measure = rawDetails['strMeasure$i'];

      if (ingredient != null &&
          ingredient.isNotEmpty &&
          ingredient.toLowerCase() != 'null') {
        ingredients.add('$measure $ingredient');
      }
    }

    // Return the updated Meal entity with full details
    return meal.copyWith(
      instructions: instructions,
      ingredients: ingredients,
      thumbnailUrl: rawDetails['strMealThumb'],
    );
  }

  // --- In-Memory Storage Implementations ---

  @override
  Future<void> savePlan(MealPlan plan) async {
    // Simulate latency before saving to in-memory list
    await Future.delayed(const Duration(milliseconds: 100));
    _savedPlans.add(plan);
  }

  @override
  Future<List<MealPlan>> getSavedPlans() async {
    // Return a copy of the in-memory list
    return List.from(_savedPlans);
  }
}
