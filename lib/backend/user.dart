import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class User extends ChangeNotifier {
  List<MapEntry<String, MapEntry<String, List<String>>>> searchHistory = [];
  List<MapEntry<String, List<String>>> allSearchEntries = [];
  Map<String, List<String>> responseHistory = {};
  Map<String, List<String>> queryHistory = {};
  Map<String, MapEntry<String, List<String>>> lastSearch = {};

  static const String _searchHistoryKey = 'searchHistory';
  static const String _allSearchEntriesKey = 'allSearchEntries';
  static const String _responseHistoryKey = 'responseHistory';
  static const String _queryHistoryKey = 'queryHistory';
  static const String _lastSearchesKey = 'lastSearch';

  // Separate init method for explicit initialization
  Future<void> init() async {
    await _loadData(); // Load user data, preferences, etc.
    notifyListeners(); // Notify listeners if anything changes
  }

  // Load data from SharedPreferences
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load searchHistory
    final searchHistoryJson = prefs.getString(_searchHistoryKey);
    if (searchHistoryJson != null) {
      final List<dynamic> searchHistoryList = jsonDecode(searchHistoryJson);
      searchHistory = searchHistoryList.map((entry) {
        final Map<String, dynamic> mapEntry = entry as Map<String, dynamic>;
        final barId = mapEntry['barId'] as String;
        final query = mapEntry['query'] as String;
        final drinkIds =
            List<String>.from(mapEntry['drinkIds'] as List<dynamic>);
        return MapEntry(barId, MapEntry(query, drinkIds));
      }).toList();
    }

    // Load allSearchEntries
    final allSearchEntriesJson = prefs.getString(_allSearchEntriesKey);
    if (allSearchEntriesJson != null) {
      final List<dynamic> allSearchEntriesList =
          jsonDecode(allSearchEntriesJson);
      allSearchEntries = allSearchEntriesList.map((entry) {
        final Map<String, dynamic> mapEntry = entry as Map<String, dynamic>;
        final query = mapEntry['query'] as String;
        final drinkIds =
            List<String>.from(mapEntry['drinkIds'] as List<dynamic>);
        return MapEntry(query, drinkIds);
      }).toList();
    }

    // Load responseHistory
    final responseHistoryJson = prefs.getString(_responseHistoryKey);
    if (responseHistoryJson != null) {
      final Map<String, dynamic> responseHistoryMap =
          jsonDecode(responseHistoryJson);
      responseHistory = responseHistoryMap.map((key, value) {
        return MapEntry(key, List<String>.from(value as List<dynamic>));
      });
    }

    // Load queryHistory
    final queryHistoryJson = prefs.getString(_queryHistoryKey);
    if (queryHistoryJson != null) {
      final Map<String, dynamic> queryHistoryMap = jsonDecode(queryHistoryJson);
      queryHistory = queryHistoryMap.map((key, value) {
        return MapEntry(key, List<String>.from(value as List<dynamic>));
      });
    }

    // Load lastSearches
    final lastSearchesJson = prefs.getString(_lastSearchesKey);
    if (lastSearchesJson != null) {
      final Map<String, dynamic> lastSearchesMap = jsonDecode(lastSearchesJson);
      lastSearch = lastSearchesMap.map((key, value) {
        final query = value['query'] as String;
        final drinkIds = List<String>.from(value['drinkIds'] as List<dynamic>);
        return MapEntry(key, MapEntry(query, drinkIds));
      });
    }

    notifyListeners();
  }

// Save data to SharedPreferences
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    // Save searchHistory
    final searchHistoryJson = jsonEncode(searchHistory.map((entry) {
      return {
        'barId': entry.key,
        'query': entry.value.key,
        'drinkIds': entry.value.value,
      };
    }).toList());
    await prefs.setString(_searchHistoryKey, searchHistoryJson);

    // Save allSearchEntries
    final allSearchEntriesJson = jsonEncode(allSearchEntries.map((entry) {
      return {
        'query': entry.key,
        'drinkIds': entry.value,
      };
    }).toList());
    await prefs.setString(_allSearchEntriesKey, allSearchEntriesJson);

    // Save responseHistory
    final responseHistoryJson =
        jsonEncode(responseHistory.map((key, value) => MapEntry(
              key,
              value,
            )));
    await prefs.setString(_responseHistoryKey, responseHistoryJson);

    // Save queryHistory
    final queryHistoryJson =
        jsonEncode(queryHistory.map((key, value) => MapEntry(
              key,
              value,
            )));
    await prefs.setString(_queryHistoryKey, queryHistoryJson);

    // Save lastSearches
    final lastSearchesJson = jsonEncode(lastSearch.map((key, value) => MapEntry(
          key,
          {
            'query': value.key,
            'drinkIds': value.value,
          },
        )));
    await prefs.setString(_lastSearchesKey, lastSearchesJson);
  }

  // Add a query to history and save it
  void addQueryToHistory(String barId, String query) {
    if (!queryHistory.containsKey(barId)) {
      queryHistory[barId] = [];
    }
    queryHistory[barId]!.add(query);

    HapticFeedback.mediumImpact();

    notifyListeners();
    _saveData(); // Save data after modification
  }

  // Retrieve query history for a specific bar
  List<String> getQueryHistory(String barId) {
    return queryHistory[barId] ?? [];
  }

  // Add a search query and its associated drink IDs to history and save it
  void addSearchQuery(String barId, String query, List<String> drinkIds) {
    searchHistory.add(MapEntry(barId, MapEntry(query, drinkIds)));
    allSearchEntries.add(MapEntry(query, drinkIds));

    notifyListeners();
    _saveData(); // Save data after modification
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
      await Future.delayed(
          const Duration(milliseconds: 15)); // Adjust the delay as needed
      responseHistory[barId]![responseHistory[barId]!.length - 1] +=
          response[i];
      //print("addResponseToHistory: Adding character '${response[i]}' to response history for barId $barId");

      HapticFeedback.mediumImpact();
      notifyListeners();
    }
    _saveData(); // Save data after modification
  }

  void clearAllHistories() async {
    responseHistory.clear();
    searchHistory.clear();
    queryHistory.clear();
    lastSearch.clear();

    // Notify listeners to update the UI
    notifyListeners();

    // Save the cleared state to SharedPreferences
  }

  // Add or update the last search for a specific bar
  void setLastSearch(String barId, String query, List<String> drinkIds) {
    lastSearch[barId] = MapEntry(query, drinkIds);
    notifyListeners();
    _saveData();
  }

  // Retrieve the last search for a specific bar
  MapEntry<String, List<String>>? getLastSearch(String barId) {
    return lastSearch[barId];
  }
}
