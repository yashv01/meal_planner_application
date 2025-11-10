// lib/data/repositories/meal_repository_impl.dart

// NEW RTDB IMPORT
import 'package:firebase_database/firebase_database.dart';

import 'package:meal_planner_app/data/datasources/meal_remote_datasource.dart';
import 'package:meal_planner_app/domain/entities/meal_plan.dart';
import 'package:meal_planner_app/domain/repositories/meal_repository.dart';

class MealRepositoryImpl implements MealRepository {
  final MealRemoteDataSource remoteDataSource;
  final FirebaseDatabase? database; // NEW RTDB property

  // Constructor updated to accept RTDB
  MealRepositoryImpl(this.remoteDataSource, {this.database});

  // (API calls and mapping logic remains the same)
  String _mapDietToCategory(String dietType) {
    if (dietType == 'Vegetarian' || dietType == 'Vegan') return 'Vegetarian';
    if (dietType == 'Seafood') return 'Seafood';
    return 'Chicken';
  }

  @override
  Future<List<Meal>> fetchMealsForPlanning({
    required String dietType,
    required List<String> restrictions,
  }) async {
    final category = _mapDietToCategory(dietType);
    final rawMeals = await remoteDataSource.fetchMealListByCategory(category);

    return rawMeals
        .map(
          (raw) => Meal(
            type: 'N/A',
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

    return meal.copyWith(
      instructions: instructions,
      ingredients: ingredients,
      thumbnailUrl: rawDetails['strMealThumb'],
    );
  }

  // Unimplemented (Logic handled by Notifier due to complex UID dependency)
  @override
  Future<void> savePlan(MealPlan plan) async {
    throw UnimplementedError(
      'Persistence handled by Notifier for UID management.',
    );
  }

  @override
  Future<List<MealPlan>> getSavedPlans() async {
    throw UnimplementedError('Loading handled by Notifier for UID management.');
  }
}
