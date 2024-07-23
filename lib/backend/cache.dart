import 'package:shared_preferences/shared_preferences.dart';

class Cache {
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
