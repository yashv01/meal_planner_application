// lib/data/datasources/meal_remote_datasource.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// --- DATA LAYER: DATA SOURCES ---
/// This class handles the actual communication with the external API/DB.
/// It returns raw data (JSON Map) to the Repository for conversion.

class MealRemoteDataSource {
  // Use the test key '1' for educational purposes as suggested by TheMealDB
  static const String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  /// Fetches a list of minimal meal data (ID, Name, Thumb) based on category.
  Future<List<Map<String, dynamic>>> fetchMealListByCategory(
    String category,
  ) async {
    // TheMealDB uses 'filter.php' to get a list of meals by category
    final url = Uri.parse('$_baseUrl/filter.php?c=$category');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // The API returns {'meals': [...]}
        final meals = data['meals'] as List<dynamic>?;
        return (meals ?? []).cast<Map<String, dynamic>>();
      } else {
        throw Exception(
          'Failed to load meal list. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      // In production, we'd log the error details, but here we provide a friendly error
      throw Exception(
        'Network error or invalid response while fetching meals.',
      );
    }
  }

  /// Fetches the full detailed recipe for a single meal ID.
  Future<Map<String, dynamic>?> fetchMealDetailsById(String id) async {
    // TheMealDB uses 'lookup.php' to get details by ID
    final url = Uri.parse('$_baseUrl/lookup.php?i=$id');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) { 
        final data = json.decode(response.body);
        final meals = data['meals'] as List<dynamic>?;
        // The API returns a list, so we grab the first item (the only one)
        return meals != null && meals.isNotEmpty
            ? meals[0].cast<String, dynamic>()
            : null;
      } else {
        throw Exception(
          'Failed to load meal details. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error while fetching meal details.');
    }
  }
}
