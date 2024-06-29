import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class User extends ChangeNotifier {
  List<MapEntry<String, MapEntry<String, List<String>>>> searchHistory = [];
  List<MapEntry<String, List<String>>> allSearchEntries = [];
  Map<String, List<String>> responseHistory = {};
  Map<String, List<String>> queryHistory = {};

  // Add a query to history
  void addQueryToHistory(String barId, String query) {
    if (!queryHistory.containsKey(barId)) {
      queryHistory[barId] = [];
    }
    queryHistory[barId]!.add(query);

    HapticFeedback.mediumImpact();

    notifyListeners();
    debugPrint('Query added to history: $query for Bar ID: $barId');
    debugPrint(
        'Current query history for Bar ID $barId: ${queryHistory[barId]}');
  }

  // Retrieve query history for a specific bar
  List<String> getQueryHistory(String barId) {
    return queryHistory[barId] ?? [];
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

  // Retrieve search history for a specific bar
  List<MapEntry<String, List<String>>> getSearchHistory(String barId) {
    return searchHistory
        .where((entry) => entry.key == barId)
        .map((entry) => entry.value)
        .toList();
  }

  // Retrieve response history for a specific bar
  List<String> getResponseHistory(String barId) {
    return responseHistory[barId] ?? [];
  }


// Add a response to the response history for a specific bar character by character
  void addResponseToHistory(String barId, String response) async {
    if (!responseHistory.containsKey(barId)) {
      responseHistory[barId] = [];
    }
    responseHistory[barId]!.add(''); // Start with an empty response

    for (int i = 0; i < response.length; i++) {
      await Future.delayed(const Duration(milliseconds: 15)); // Adjust the delay as needed
      responseHistory[barId]![responseHistory[barId]!.length - 1] += response[i];
      HapticFeedback.mediumImpact();
      notifyListeners();
    }
  }

}
