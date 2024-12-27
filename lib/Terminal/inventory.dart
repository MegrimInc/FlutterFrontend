import 'dart:convert';

import 'package:barzzy/Backend/bar.dart';
import 'package:barzzy/Backend/categories.dart';
import 'package:barzzy/Backend/drink.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Inventory extends ChangeNotifier {
  late Bar bar;
  final Map<String, Drink> _drinks = {};
  late Categories categories;

  Future<void> fetchBarDetails(int barId) async {
    const String baseUrl = "https://www.barzzy.site"; // Define URL locally
    try {

      final response = await http.get(Uri.parse("$baseUrl/bars/$barId"));
      debugPrint("Received response with status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("Response data: $data");

        setBar(Bar.fromJson(data));
        debugPrint("Parsed bar object: $bar");

        await fetchTagsAndDrinks(barId);

      } else {
        throw Exception(
            "Failed to fetch bar details. Status: ${response.statusCode}");
      }
    } catch (error) {
      debugPrint("Error fetching bar details: $error");
    }
  }

  Future<void> fetchTagsAndDrinks(int barId) async {
    debugPrint('Fetching drinks for bar ID: $barId');

    // KEEP PLEASE
    // ignore: unused_local_variable
    List<MapEntry<int, String>> tagList = [
      const MapEntry(179, 'lager'),
      const MapEntry(172, 'vodka'),
      const MapEntry(175, 'tequila'),
      const MapEntry(174, 'whiskey'),
      const MapEntry(173, 'gin'),
      const MapEntry(176, 'brandy'),
      const MapEntry(177, 'rum'),
      const MapEntry(186, 'seltzer'),
      const MapEntry(178, 'ale'),
      const MapEntry(183, 'red wine'),
      const MapEntry(184, 'white wine'),
      const MapEntry(181, 'virgin'),
    ];

    Categories categories = Categories(
      barId: barId,
      tag172: [],
      tag173: [],
      tag174: [],
      tag175: [],
      tag176: [],
      tag177: [],
      tag178: [],
      tag179: [],
      tag181: [],
      tag183: [],
      tag184: [],
      tag186: [],
    );

    final url =
        Uri.parse('https://www.barzzy.site/bars/getAllDrinksByBar/$barId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      //debugPrint('Drinks JSON response for bar $barId: $jsonResponse');

      for (var drinkJson in jsonResponse) {
        String? drinkId = drinkJson['drinkId']?.toString();
        //debugPrint('Processing drink: $drinkJson');

        if (drinkId != null) {
          Drink drink = Drink.fromJson(drinkJson);

          addDrink(drink);

          debugPrint('Drink with ID: ${drink.id} added to Inventory.');

          for (String tagId in drink.tagId) {
            //debugPrint('Processing tagId: $tagId for drinkId: $drinkId');
            switch (int.parse(tagId)) {
              case 172:
                categories.tag172.add(int.parse(drinkId));
                break;
              case 173:
                categories.tag173.add(int.parse(drinkId));
                break;
              case 174:
                categories.tag174.add(int.parse(drinkId));
                break;
              case 175:
                categories.tag175.add(int.parse(drinkId));
                break;
              case 176:
                categories.tag176.add(int.parse(drinkId));
                break;
              case 177:
                categories.tag177.add(int.parse(drinkId));
                break;
              case 178:
                categories.tag178.add(int.parse(drinkId));
                break;
              case 179:
                categories.tag179.add(int.parse(drinkId));
                break;
              case 181:
                categories.tag181.add(int.parse(drinkId));
                break;
              case 183:
                categories.tag183.add(int.parse(drinkId));
                break;
              case 184:
                categories.tag184.add(int.parse(drinkId));
                break;
              case 186:
                categories.tag186.add(int.parse(drinkId));
                break;
              default:
              //debugPrint('Unknown tagId: $tagId for drinkId: $drinkId');
            }
          }
        } else {
          debugPrint('Warning: Drink ID is null for drink: $drinkJson');
        }
      }
      setCategories(categories);
      debugPrint('Drinks for bar $barId have been categorized and added to the Inventory object.');
    } else {
      debugPrint(
          'Failed to load drinks for bar $barId. Status code: ${response.statusCode}');
    }

    debugPrint('Finished processing drinks for barId: $barId');
  }

  // Setters for the bar object
  void setBar(Bar newBar) {
    bar = newBar;
    notifyListeners(); // Notify listeners of the change
  }

  // Add a drink to the map
  void addDrink(Drink drink) {
    _drinks[drink.id] = drink;
    notifyListeners(); // Notify listeners of the change
  }

  // Set categories object
  void setCategories(Categories categories) {
    categories = categories;
    notifyListeners(); // Notify listeners of the change
  }
}
