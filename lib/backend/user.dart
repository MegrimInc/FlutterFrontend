import 'package:barzzy_app1/backend/categories.dart';
import 'package:flutter/foundation.dart';

class User extends ChangeNotifier {
  static final User _singleton = User._internal();

  factory User() {
    return _singleton;
  }

  User._internal();

  // Map to store Categories objects with barId as the key
  Map<String, Categories> categoriesMap = {};

  void addCategories(String barId, Categories categories) {
    categoriesMap[barId] = categories;
    notifyListeners();
  }

  // Method to get random drink IDs for a bar
  Map<String, List<int>> getRandomDrinksByBarId(String barId) {
    final categories = categoriesMap[barId];
    return categories?.getRandomDrinkIds() ?? {};
  }

  // Method to trigger a UI update
  void triggerUIUpdate() {
    notifyListeners();
  }
}
