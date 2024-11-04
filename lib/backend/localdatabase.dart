import 'package:barzzy/Backend/activeorder.dart';
import 'package:barzzy/Backend/tags.dart';

import 'package:barzzy/Backend/drink.dart';
import 'package:barzzy/Backend/point.dart';

import 'package:flutter/material.dart';
import 'bar.dart';

class LocalDatabase with ChangeNotifier {
  static final LocalDatabase _singleton = LocalDatabase._internal();

  factory LocalDatabase() {
    return _singleton;
  }

  LocalDatabase._internal();

  final Map<String, Bar> _bars = {};
  final Map<String, Tag> tags = {};
  final Map<String, Drink> _drinks = {};
  final Map<String, CustomerOrder> _barOrders = {};
  final Map<String, Point> _userPoints = {};

  void addOrUpdateOrderForBar(CustomerOrder order) {
    _barOrders[order.barId] = order;
    notifyListeners();
  }

  CustomerOrder? getOrderForBar(String barId) {
    return _barOrders[barId];
  }

  // Method to add a new bar, generating an ID for it
  void addBar(Bar bar) {
    if (bar.id != null) {
      _bars[bar.id!] = bar;
      notifyListeners();
      debugPrint(
          'Bar with ID: ${bar.id} added by LocalDatabase instance: $hashCode.');
    } else {
      debugPrint('Bar ID is null, cannot add to database.');
    }
  }

  void addDrink(Drink drink) {
    _drinks[drink.id] = drink;
    notifyListeners();
    debugPrint('Drink with ID: ${drink.id} added to LocalDatabase. Total drinks: ${_drinks.length}');
  }

  void addTag(Tag tag) {
    tags[tag.id] = tag;
    notifyListeners();
  }

  // Method to get minimal information necessary for search
  Map<String, Map<String, String>> getSearchableBarInfo() {
    return _bars.map((id, bar) =>
        MapEntry(id, {'name': bar.name ?? '', 'address': bar.address ?? ''}));
  }

  //Method to get all bar IDs
  List<String> getAllBarIds() {
    return _bars.keys.toList();
  }

  static Bar? getBarById(String id) {
    return _singleton._bars[id];
  }

  Drink getDrinkById(String id) {
    //debugPrint('Drink found for ID: $id in LocalDatabase instance: $hashCode');
    return _drinks[id]!;
  }

  void clearOrders() {
    _barOrders.clear();
    notifyListeners();
    debugPrint("All orders have been cleared.");
    _userPoints.clear();
    debugPrint("All points have been cleared.");
  }

  void addOrUpdatePoints(String barId, int points) {
    _userPoints[barId] = Point(barId: barId, points: points);
    notifyListeners();
    debugPrint('Points updated for bar $barId: $points points');
  }

  // Method to get points for a specific bar
  Point? getPointsForBar(String barId) {
    return _userPoints[barId];
  }

  // Method to get all points for the user
  Map<String, Point> getAllPoints() {
    return _userPoints;
  }

  void clearPoints() {
  _userPoints.clear();
  notifyListeners();
  debugPrint('All points have been cleared.');
}
}
