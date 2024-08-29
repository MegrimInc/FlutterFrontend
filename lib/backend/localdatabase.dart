import 'dart:convert';
import 'package:barzzy_app1/Backend/activeorder.dart';
import 'package:http/http.dart' as http;
import 'package:barzzy_app1/Backend/drink.dart';
import 'package:barzzy_app1/Backend/response.dart';
import 'package:barzzy_app1/Backend/user.dart';
import 'package:flutter/material.dart';
import 'bar.dart';
import 'tags.dart';
import 'package:barzzy_app1/Backend/cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDatabase with ChangeNotifier {
  static final LocalDatabase _singleton = LocalDatabase._internal();
  static const String _orderPrefsKey = 'orders';

  factory LocalDatabase() {
    return _singleton;
  }

  LocalDatabase._internal() {
    // Automatically load orders when the class is instantiated
    //loadOrdersFromSharedPreferences();
  }

  final Map<String, Bar> _bars = {};
  final Map<String, Tag> tags = {};
  final Map<String, Drink> _drinks = {};
  final Cache _cache = Cache();
  final Map<String, CustomerOrder> _barOrders = {};

  void addOrUpdateOrderForBar(CustomerOrder order) async {
    _barOrders[order.barId] = order;
    //await _saveOrdersToSharedPreferences();
    notifyListeners();
  }

  // Method to clear only the bar orders and related persisted data
  Future<void> clearBarOrders() async {
    // Clear in-memory bar orders
    _barOrders.clear();

    // Clear persisted bar orders in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_orderPrefsKey);

    notifyListeners(); // Notify listeners that the bar orders have been cleared
  }

  CustomerOrder? getOrderForBar(String barId) {
    return _barOrders[barId];
  }

  // Method to add a new bar, generating an ID for it
  void addBar(Bar bar) {
    if (bar.id != null) {
      _bars[bar.id!] = bar;
      notifyListeners();
    } else {
      debugPrint('Bar ID is null, cannot add to database.');
    }
  }

  void addDrink(Drink drink) {
    _drinks[drink.id] = drink;
    notifyListeners();
  }

// Method to add a new tag
  void addTag(Tag tag) {
    tags[tag.id] = tag;
    //debugPrint('Adding tag - ID: ${tag.id}, Name: ${tag.name}');
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
    return _drinks[id]!;
  }

  Future<Set<String>> fetchDrinksByTag(String barId, String tagId) async {
    // Define the endpoint URL
    final url = Uri.parse(
        'https://www.barzzy.site/bars/getDrinks?categoryId=$tagId&barId=$barId');

    Set<String> drinkIds = {};

    try {
      // Make the GET request
      final response = await http.get(url);

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Parse the JSON response
        final List<dynamic> jsonResponse = jsonDecode(response.body);
        debugPrint('Drinks data received: $jsonResponse');

        for (var drinkJson in jsonResponse) {
          Drink drink = Drink.fromJson(drinkJson);
          // debugPrint('Parsed Bar Name: ${bar.name}');
          // debugPrint('Parsed Bar Image: ${bar.barimg}');
          // debugPrint('Parsed Tag Image: ${bar.tagimg}');
          addDrink(drink);
          drinkIds.add(drink.id);
        }

        // Add fetched drink IDs to cache
        for (var drinkId in drinkIds) {
          await _cache.addDrinkId(drinkId);
        }
      } else {
        debugPrint(
            'Failed to load drinks. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any errors during the request
      debugPrint('Error fetching drinks: $e');
    }
    return drinkIds;
  }

  void searchDrinks(String query, User user, String barId) async {
    user.addQueryToHistory(barId, query);
    Set<String> filteredIdsSet = {};
    Set<String> ids = {};
    query = query.toLowerCase().replaceAll(' ', '');

    debugPrint('Search query received: $query');

    // Iterate over each tag in _tags to find matches
    tags.forEach((id, tag) {
      if (tag.name.toLowerCase().contains(query)) {
        debugPrint('Tag matches query - ID: $id, Name: ${tag.name}');
        filteredIdsSet.addAll([id]);
      }
    });

    List<String> filteredIds = filteredIdsSet.toList();

    debugPrint(
        'Filtered IDs for query $query: $filteredIds'); // Print the filtered IDs

    // Fetch drinks for each tag ID
    for (String tagId in filteredIds) {
      Set<String> returnedids = await fetchDrinksByTag(barId, tagId);
      ids.addAll(returnedids);
    }

    List<String> drinkIds = ids.toList();
    user.addSearchQuery(barId, query, drinkIds);

    user.setLastSearch(barId, query, drinkIds);

    if (drinkIds.isEmpty) {
      Response().addNegativeResponse(user, barId, query);
    } else {
      Response().addPositiveResponse(user, barId, drinkIds.length, query);
    }
  }

  Future<List<String>> fetchSixDrinks(User user, String barId) async {
    // Define the endpoint URL
    final url =
        Uri.parse('https://www.barzzy.site/bars/getSixDrinks?barId=$barId');

    List<String> drinkIds = [];

    try {
      // Make the GET request
      final response2 = await http.get(url);

      // Check if the request was successful
      if (response2.statusCode == 200) {
        // Parse the JSON response
        final List<dynamic> jsonResponse = jsonDecode(response2.body);
        debugPrint('Six drinks data received: $jsonResponse');

        for (var drinkJson in jsonResponse) {
          Drink drink = Drink.fromJson(drinkJson);
          addDrink(drink); // Add each drink to the local database
          drinkIds.add(drink.id); // Collect the drink IDs
        }

        // Add fetched drink IDs to cache
        for (var drinkId in drinkIds) {
          await _cache.addDrinkId(drinkId);
        }
        String response = "";
   String query = "";
   user.addResponseToHistory(barId, response);
   user.addQueryToHistory(barId, query);
   user.addSearchQuery(barId, query, drinkIds);
   user.setLastSearch(barId, query, drinkIds);
      } else {
        debugPrint(
            'Failed to load six drinks. Status code: ${response2.statusCode}');
      }
    } catch (e) {
      // Handle any errors during the request
      debugPrint('Error fetching six drinks: $e');
    }
    return drinkIds;
  }
}
