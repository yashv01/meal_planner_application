// lib/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meal_planner_app/domain/entities/meal_plan.dart';
import 'package:meal_planner_app/presentation/providers/meal_planner_notifier.dart';
import 'package:meal_planner_app/presentation/screens/recipe_detail_screen.dart';
import 'package:meal_planner_app/presentation/screens/loading_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Form state
  final _formKey = GlobalKey<FormState>();
  String _selectedGoal = 'Maintenance';
  String _selectedDiet = 'Standard';
  String _selectedDuration = '7 Days';
  final List<String> _selectedMeals = const ['Breakfast', 'Lunch', 'Dinner'];

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<MealPlannerNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planner Pro (V1)'),
        actions: [
          if (notifier.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // USER MENU (Name and Logout)
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await notifier.signOutUser();
                // Navigate back to the loading screen to check the new auth state
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const LoadingScreen(),
                    ),
                  );
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              // Display User Name
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Logged in as:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      notifier.username,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              // Logout Action
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.account_circle, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Your Personalized Plan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const Divider(height: 30),

            _buildGenerationForm(notifier),

            if (notifier.errorMessage != null)
              _buildErrorBanner(notifier.errorMessage!),

            const SizedBox(height: 30),
            Text(
              'My Saved Plans (${notifier.savedPlans.length})',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
            ),
            const Divider(height: 20),

            _buildSavedPlansList(notifier.savedPlans, notifier),
          ],
        ),
      ),
    );
  }

  // (Builder methods are the same)

  Widget _buildGenerationForm(MealPlannerNotifier notifier) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDropdownTile(
            title: 'Goal',
            value: _selectedGoal,
            items: ['Maintenance', 'Weight Loss', 'Muscle Gain'],
            onChanged: (newValue) => setState(() => _selectedGoal = newValue!),
          ),

          _buildDropdownTile(
            title: 'Diet Type',
            value: _selectedDiet,
            items: ['Standard', 'Vegetarian', 'Vegan', 'Seafood'],
            onChanged: (newValue) => setState(() => _selectedDiet = newValue!),
          ),

          _buildDropdownTile(
            title: 'Plan Duration',
            value: _selectedDuration,
            items: ['1 Day', '3 Days', '7 Days'],
            onChanged: (newValue) =>
                setState(() => _selectedDuration = newValue!),
          ),

          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: notifier.isLoading
                ? null
                : () => _handleGeneratePlan(notifier),
            icon: const Icon(Icons.auto_awesome),
            label: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                notifier.isLoading
                    ? 'Generating...'
                    : 'Generate & Save Meal Plan',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Card(
      color: Colors.red.shade100,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Error: $message',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: value,
                items: items.map<DropdownMenuItem<String>>((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleGeneratePlan(MealPlannerNotifier notifier) {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final durationDays = int.parse(_selectedDuration.split(' ')[0]);

      notifier.generateAndSavePlan(
        goal: _selectedGoal,
        dietType: _selectedDiet,
        durationDays: durationDays,
        mealTypes: _selectedMeals,
        restrictions: [],
      );
    }
  }

  Widget _buildSavedPlansList(
    List<MealPlan> plans,
    MealPlannerNotifier notifier,
  ) {
    if (plans.isEmpty && !notifier.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            "No saved meal plans found. Generate one above to start!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            title: Text(
              '${plan.dietType} Plan (${plan.days.length} Days)',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              'Goal: ${plan.goal} • Created: ${plan.creationDate.day}/${plan.creationDate.month}/${plan.creationDate.year}',
              style: const TextStyle(color: Colors.grey),
            ),
            // DELETE: Calls Firestore delete logic
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => notifier.deletePlan(plan.id),
            ),
            children: plan.days
                .map((dayPlan) => _buildDayTile(context, dayPlan))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildDayTile(BuildContext context, DayPlan dayPlan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 4.0),
          child: Text(
            dayPlan.day,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.teal.shade600,
              fontSize: 16,
            ),
          ),
        ),
        ...dayPlan.meals
            .map((meal) => _buildMealListTile(context, meal))
            .toList(),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildMealListTile(BuildContext context, Meal meal) {
    return ListTile(
      leading: SizedBox(
        width: 48,
        height: 48,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: meal.thumbnailUrl != null && meal.thumbnailUrl!.isNotEmpty
              ? Image.network(
                  meal.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, color: Colors.red),
                )
              : const Icon(Icons.fastfood, color: Colors.teal),
        ),
      ),
      title: Text(meal.name, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        meal.type,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (ctx) => RecipeDetailScreen(meal: meal)),
        );
      },
    );
  }
}
