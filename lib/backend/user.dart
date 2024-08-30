import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class User extends ChangeNotifier {
  static final User _singleton = User._internal();

  factory User() {
    return _singleton;
  }

  User._internal();

  List<MapEntry<String, MapEntry<String, List<String>>>> searchHistory = [];
  Map<String, List<String>> queryHistory = {};

  // Add a query to history
  void addQueryToHistory(String barId, String query) {
    if (!queryHistory.containsKey(barId)) {
      queryHistory[barId] = [];
    }
    queryHistory[barId]!.add(query);

    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  // Retrieve query history for a specific bar
  List<String> getQueryHistory(String barId) {
    return queryHistory[barId] ?? [];
  }

  // Add a search query and its associated drink IDs to history
  void addSearchQuery(String barId, String query, List<String> drinkIds) {
    searchHistory.add(MapEntry(barId, MapEntry(query, drinkIds)));
    notifyListeners();
  }

  // Retrieve search history for a specific bar
  List<MapEntry<String, List<String>>> getSearchHistory(String barId) {
    return searchHistory
        .where((entry) => entry.key == barId)
        .map((entry) => entry.value)
        .toList();
  }

  // Clear all histories
  void clearAllHistories() {
    searchHistory.clear();
    queryHistory.clear();
    notifyListeners();
  }

  // Clear histories for a specific bar
  void clearHistoriesForBar(String barId) {
    searchHistory.removeWhere((entry) => entry.key == barId);
    queryHistory.remove(barId);
    notifyListeners();
  }
}