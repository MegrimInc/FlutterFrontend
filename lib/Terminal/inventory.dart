import 'dart:convert';

import 'package:barzzy/Backend/bar.dart';
import 'package:barzzy/Backend/categories.dart';
import 'package:barzzy/Backend/drink.dart';
import 'package:barzzy/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Inventory extends ChangeNotifier {
  static final Inventory _instance = Inventory._internal();

  // Step 2: Private constructor
  Inventory._internal();

  // Step 3: Factory method to return the instance
  factory Inventory() {
    return _instance;
  }

  late Bar bar;
  final Map<String, Drink> _drinks = {};
  late Categories categories;
  final Map<String, int> _inventoryCart = {};
  final List<String> _inventoryOrder = [];
  String _selectedCategory = 'tag172';

  Future<void> fetchBarDetails(int barId) async {
    
    try {
      //TODO:  final response = await http.get(Uri.parse("https://www.barzzy.site/bars/$barId"));

      final response = await http.get(Uri.parse('${AppConfig.postgresApiBaseUrl}/customer/$barId'));
      //debugPrint("Received response with status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("Response data: $data");

        setBar(Bar.fromJson(data));
        //debugPrint("Parsed bar object: $bar");

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

    categories = Categories(
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
      tagSpecial: [],
    );

    final url = Uri.parse('${AppConfig.postgresApiBaseUrl}/customer/getAllItemsByMerchant/$barId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      //debugPrint('Drinks JSON response for bar $barId: $jsonResponse');

      for (var drinkJson in jsonResponse) {
        String? drinkId = drinkJson['itemId']?.toString();
        //debugPrint('Processing drink: $drinkJson');

        if (drinkId != null) {
          Drink drink = Drink.fromJson(drinkJson);

          setDrinks(drink);

          debugPrint('Drink with ID: ${drink.itemId} added to Inventory.');

          if (drink.categories.length > 1) {
            // If the drink has multiple tags, add it to the Special category
            categories.tagSpecial.add(int.parse(drinkId));
          } else {
            for (String tagId in drink.categories) {
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
          }
        } else {
          debugPrint('Warning: Drink ID is null for drink: $drinkJson');
        }
      }
      setCategories(categories);
      debugPrint(
          'Drinks for bar $barId have been categorized and added to the Inventory object.');
    } else {
      debugPrint(
          'Failed to load drinks for bar $barId. Status code: ${response.statusCode}');
    }

    debugPrint('Finished processing drinks for barId: $barId');
  }

  void addDrink(String drinkId) {
  
    // Initialize the drink's map if it doesn't exist
    _inventoryCart.putIfAbsent(drinkId, () => 0);
   _inventoryCart.update(drinkId, (quantity) => quantity + 1, ifAbsent: () => 1);


    debugPrint("Instance ID: $hashCode");
    debugPrint('Updated inventory cart: $_inventoryCart');

    if (!_inventoryOrder.contains(drinkId)) {
      _inventoryOrder.add(drinkId);
    }

    notifyListeners();
  }


  void removeDrink(String drinkId) {
  if (_inventoryCart.containsKey(drinkId)) {
    _inventoryCart[drinkId] = _inventoryCart[drinkId]! - 1;

    if (_inventoryCart[drinkId]! <= 0) {
      _inventoryCart.remove(drinkId);
      _inventoryOrder.remove(drinkId);
    }

    notifyListeners();
  } else {
    debugPrint('Drink with ID $drinkId not found in cart.');
  }
}


  String serializeInventoryCart(Map<String, int> inventoryCart, String bartenderId) {
  final barId = bar.id;
  final List<Map<String, dynamic>> cartItems = inventoryCart.entries.map((entry) {
    return {
      "drinkId": int.parse(entry.key),
      "quantity": entry.value,
    };
  }).toList();

  final String barIdWithBartender = "$barId$bartenderId";

  final Map<String, dynamic> result = {
    "id": barIdWithBartender,
    "order": cartItems,
  };

  return jsonEncode(result);
}


  // Setters for the bar object
  void setBar(Bar newBar) {
    bar = newBar;
    notifyListeners(); // Notify listeners of the change
  }

  // Add a drink to the map
  void setDrinks(Drink drink) {
    _drinks[drink.itemId] = drink;
    notifyListeners(); // Notify listeners of the change
  }

  // Set categories object
  void setCategories(Categories categories) {
    categories = categories;
    notifyListeners(); // Notify listeners of the change
  }

  Drink? getDrinkById(String drinkId) {
    return _drinks[drinkId];
  }

  List<int> getCategoryDrinks(String categoryTag) {
    switch (categoryTag) {
      case 'tag172':
        return categories.tag172;
      case 'tag173':
        return categories.tag173;
      case 'tag174':
        return categories.tag174;
      case 'tag175':
        return categories.tag175;
      case 'tag176':
        return categories.tag176;
      case 'tag177':
        return categories.tag177;
      case 'tag178':
        return categories.tag178;
      case 'tag179':
        return categories.tag179;
      case 'tag181':
        return categories.tag181;
      case 'tag183':
        return categories.tag183;
      case 'tag184':
        return categories.tag184;
      case 'tag186':
        return categories.tag186;
      case 'special':
        return categories.tagSpecial;
      default:
        return [];
    }
  }

  Map<String, int> get inventoryCart => _inventoryCart;

  String get selectedCategory => _selectedCategory;

  List<String> get inventoryOrder => _inventoryOrder;

  // Method to set the selected category
  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners(); // Notify widgets about the change
  }

  void clearInventory() {
    _inventoryCart.clear();
    _inventoryOrder.clear();
    notifyListeners(); // Notify UI to refresh only when necessary
  }
}
