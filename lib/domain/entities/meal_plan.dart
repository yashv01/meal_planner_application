// lib/domain/entities/meal_plan.dart

/// --- DOMAIN LAYER: ENTITIES (MODELS) ---
/// These are the core business objects. They contain data and are free 
/// from any knowledge of Flutter widgets or specific data sources (API/DB).

class Meal {
  final String type; // e.g., 'Breakfast', 'Lunch', 'Dinner'
  final String name;
  final String recipeId;
  final String? thumbnailUrl;
  
  // Full details are optional and will be loaded lazily on the detail screen.
  final String? instructions; 
  final List<String> ingredients;

  Meal({
    required this.type,
    required this.name,
    required this.recipeId,
    this.thumbnailUrl,
    this.instructions,
    this.ingredients = const [],
  });

  // Simple copyWith method to update a Meal with full recipe details after fetching.
  Meal copyWith({
    String? instructions,
    List<String>? ingredients,
    String? thumbnailUrl,
  }) {
    return Meal(
      type: type,
      name: name,
      recipeId: recipeId,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      instructions: instructions ?? this.instructions,
      ingredients: ingredients ?? this.ingredients,
    );
  }
}

class DayPlan {
  final String day; // e.g., 'Monday'
  final List<Meal> meals;

  DayPlan({required this.day, required this.meals});
}

class MealPlan {
  final String id; // Unique ID
  final String goal;
  final String dietType;
  final DateTime creationDate;
  final List<DayPlan> days;

  MealPlan({
    required this.id,
    required this.goal,
    required this.dietType,
    required this.creationDate,
    required this.days,
  });
}