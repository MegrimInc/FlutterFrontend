import 'package:flutter/foundation.dart';

class User extends ChangeNotifier {
  List<MapEntry<String, MapEntry<String, List<String>>>> searchHistory = [];
  List<MapEntry<String, List<String>>> allSearchEntries = [];
  Map<String, List<String>> responseHistory = {};



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




// Add a response to the response history for a specific bar
  void addResponseToHistory(String barId, String response) {
    if (!responseHistory.containsKey(barId)) {
      responseHistory[barId] = [];
    }
    responseHistory[barId]!.add(response);
    notifyListeners();
  }

  // Retrieve response history for a specific bar
  List<String> getResponseHistory(String barId) {
    return responseHistory[barId] ?? [];
  }





}
