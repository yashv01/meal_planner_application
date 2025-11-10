// lib/presentation/screens/recipe_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:meal_planner_app/domain/entities/meal_plan.dart';
import 'package:meal_planner_app/presentation/providers/meal_planner_notifier.dart';
import 'package:provider/provider.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Meal meal;
  const RecipeDetailScreen({super.key, required this.meal});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Future<Meal> _detailedMealFuture;

  @override
  void initState() {
    super.initState();
    // Start fetching the full details as soon as the screen opens
    _detailedMealFuture = context.read<MealPlannerNotifier>().getDetailedRecipe(
      widget.meal,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.meal.name)),
      body: FutureBuilder<Meal>(
        future: _detailedMealFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading recipe details: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final meal = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meal Image (Hero)
                if (meal.thumbnailUrl != null)
                  Image.network(
                    meal.thumbnailUrl!,
                    fit: BoxFit.cover,
                    height: 250,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(
                          height: 250,
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                  ),

                // Content Padding
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      Text(
                        'Meal Type: ${meal.type}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                      const Divider(height: 30),

                      // Ingredients Section
                      _buildSectionTitle('Ingredients'),
                      const SizedBox(height: 8),
                      if (meal.ingredients.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: meal.ingredients
                              .map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8.0,
                                    bottom: 4.0,
                                  ),
                                  child: Text(
                                    '• $item',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              )
                              .toList(),
                        )
                      else
                        const Text(
                          'No ingredients listed.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),

                      const Divider(height: 30),

                      // Instructions Section
                      _buildSectionTitle('Instructions'),
                      const SizedBox(height: 8),
                      Text(
                        meal.instructions ??
                            'Instructions currently unavailable.',
                        style: const TextStyle(fontSize: 15, height: 1.5),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.teal.shade600,
      ),
    );
  }
}
