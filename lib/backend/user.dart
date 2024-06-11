import 'package:flutter/foundation.dart';

class User extends ChangeNotifier {
  List<String> searchHistory = [];

  List<String> getSearchHistory() {
    return searchHistory;
  }

  void addSearchQuery(String query) {
    searchHistory.add(query);
    notifyListeners();
    print('Search query added: $query');
    print('Current search history: $searchHistory');
  }
}
