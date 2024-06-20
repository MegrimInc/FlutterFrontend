import 'package:barzzy_app1/Backend/drink.dart';
import 'package:flutter/foundation.dart';

class User extends ChangeNotifier {
  List<MapEntry<String, MapEntry<String, List<String>>>> searchHistory = [];
  List<MapEntry<String, List<String>>> allSearchEntries = [];



  // Retrieve search history for a specific bar
  List<MapEntry<String, List<String>>> getSearchHistory(String barId) {
    return searchHistory
        .where((entry) => entry.key == barId)
        .map((entry) => entry.value)
        .toList();
  }

  // Add a search query and its associated drink IDs to history
  void addSearchQuery(String barId, String query, List<String> drinkIds) {
   searchHistory.add(MapEntry(barId, MapEntry(query, drinkIds)));
   allSearchEntries.add(MapEntry(query, drinkIds));

    notifyListeners();
    debugPrint('Search query added: $query for Bar ID: $barId');
    debugPrint('Current search history: $searchHistory');
    debugPrint('All search entries: $allSearchEntries');
  }













}
