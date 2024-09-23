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

  // Method to get full list of drink IDs for a bar by categories
  Map<String, List<int>> getFullDrinkListByBarId(String barId) {
    final categories = categoriesMap[barId];
    return {
      'tag172': categories?.tag172 ?? [],
      'tag173': categories?.tag173 ?? [],
      'tag174': categories?.tag174 ?? [],
      'tag175': categories?.tag175 ?? [],
      'tag176': categories?.tag176 ?? [],
      'tag177': categories?.tag177 ?? [],
      'tag178': categories?.tag178 ?? [],
      'tag179': categories?.tag179 ?? [],
      'tag181': categories?.tag181 ?? [],
      'tag183': categories?.tag183 ?? [],
      'tag184': categories?.tag184 ?? [],
      'tag186': categories?.tag186 ?? [],
    };
  }

  // Method to trigger a UI update
  void triggerUIUpdate() {
    notifyListeners();
  }
}
