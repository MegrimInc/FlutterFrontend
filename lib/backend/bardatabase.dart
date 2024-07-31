import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:barzzy_app1/Backend/drink.dart';
import 'package:barzzy_app1/Backend/response.dart';
import 'package:barzzy_app1/Backend/user.dart';
import 'package:flutter/material.dart';
import 'bar.dart';
import 'tags.dart';
import 'package:barzzy_app1/Backend/cache.dart';

class BarDatabase with ChangeNotifier {
  static final BarDatabase _singleton = BarDatabase._internal();

  factory BarDatabase() {
    return _singleton;
  }

  BarDatabase._internal();

  final Map<String, Bar> _bars = {};
  final Map<String, Tag> tags = {};
  final Map<String, Drink> _drinks = {};
  final Cache _cache = Cache();

  

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

      // if (drinkIds.isEmpty) {
      //   Response().addNegativeResponse(user, barId);
      // } else {
      //   Response().addPositiveResponse(user, barId);
      // }

      if (drinkIds.isEmpty) {
    Response().addNegativeResponse(user, barId, query);
  } else {
    Response().addPositiveResponse(user, barId, drinkIds.length, query);
  }

    } 
  }

