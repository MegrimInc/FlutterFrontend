import 'package:shared_preferences/shared_preferences.dart';

class Cache {
  static final Cache _instance = Cache._internal();
  factory Cache() => _instance; // Factory constructor to return the same instance

  Cache._internal(); // Private constructor
  static const _drinkIdsKey = 'drinkIds';

  // Add a drink ID to the cache
  Future<void> addDrinkId(String drinkId) async {
    final prefs = await SharedPreferences.getInstance();
    final existingIds = prefs.getStringList(_drinkIdsKey) ?? [];
    
    if (!existingIds.contains(drinkId)) {
      existingIds.add(drinkId);
      await prefs.setStringList(_drinkIdsKey, existingIds);
    }
  }

  // Get all drink IDs from the cache
  Future<Set<String>> getDrinkIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_drinkIdsKey) ?? [];
    return ids.toSet();
  }
}
