import 'dart:convert';

import 'package:barzzy/Backend/merchant.dart';
import 'package:barzzy/Backend/categories.dart';
import 'package:barzzy/Backend/item.dart';
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

  late Merchant merchant;
  final Map<String, Item> _items = {};
  late Categories categories;
  final Map<String, int> _inventoryCart = {};
  final List<String> _inventoryOrder = [];
  String _selectedCategory = 'tag172';

  Future<void> fetchMerchantDetails(int merchantId) async {
    
    try {
      //TODO:  final response = await http.get(Uri.parse("https://www.barzzy.site/merchants/$merchantId"));

      final response = await http.get(Uri.parse('${AppConfig.postgresApiBaseUrl}/customer/$merchantId'));
      //debugPrint("Received response with status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("Response data: $data");

        setMerchant(Merchant.fromJson(data));
        //debugPrint("Parsed merchant object: $merchant");

        await fetchTagsAndItems(merchantId);
      } else {
        throw Exception(
            "Failed to fetch merchant details. Status: ${response.statusCode}");
      }
    } catch (error) {
      debugPrint("Error fetching merchant details: $error");
    }
  }

  Future<void> fetchTagsAndItems(int merchantId) async {
    debugPrint('Fetching items for merchant Id: $merchantId');

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
      merchantId: merchantId,
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

    final url = Uri.parse('${AppConfig.postgresApiBaseUrl}/customer/getAllItemsByMerchant/$merchantId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      //debugPrint('Items JSON response for merchant $merchantId: $jsonResponse');

      for (var itemJson in jsonResponse) {
        String? itemId = itemJson['itemId']?.toString();
        //debugPrint('Processing item: $itemJson');

        if (itemId != null) {
          Item item = Item.fromJson(itemJson);

          setItems(item);

          debugPrint('Item with Id: ${item.itemId} added to Inventory.');

          if (item.categories.length > 1) {
            // If the item has multiple tags, add it to the Special category
            categories.tagSpecial.add(int.parse(itemId));
          } else {
            for (String tagId in item.categories) {
              //debugPrint('Processing tagId: $tagId for itemId: $itemId');
              switch (int.parse(tagId)) {
                case 172:
                  categories.tag172.add(int.parse(itemId));
                  break;
                case 173:
                  categories.tag173.add(int.parse(itemId));
                  break;
                case 174:
                  categories.tag174.add(int.parse(itemId));
                  break;
                case 175:
                  categories.tag175.add(int.parse(itemId));
                  break;
                case 176:
                  categories.tag176.add(int.parse(itemId));
                  break;
                case 177:
                  categories.tag177.add(int.parse(itemId));
                  break;
                case 178:
                  categories.tag178.add(int.parse(itemId));
                  break;
                case 179:
                  categories.tag179.add(int.parse(itemId));
                  break;
                case 181:
                  categories.tag181.add(int.parse(itemId));
                  break;
                case 183:
                  categories.tag183.add(int.parse(itemId));
                  break;
                case 184:
                  categories.tag184.add(int.parse(itemId));
                  break;
                case 186:
                  categories.tag186.add(int.parse(itemId));
                  break;
                default:
                //debugPrint('Unknown tagId: $tagId for itemId: $itemId');
              }
            }
          }
        } else {
          debugPrint('Warning: Item Id is null for item: $itemJson');
        }
      }
      setCategories(categories);
      debugPrint(
          'Items for merchant $merchantId have been categorized and added to the Inventory object.');
    } else {
      debugPrint(
          'Failed to load items for merchant $merchantId. Status code: ${response.statusCode}');
    }

    debugPrint('Finished processing items for merchantId: $merchantId');
  }

  void addItem(String itemId) {
  
    // Initialize the item's map if it doesn't exist
    _inventoryCart.putIfAbsent(itemId, () => 0);
   _inventoryCart.update(itemId, (quantity) => quantity + 1, ifAbsent: () => 1);


    debugPrint("Instance Id: $hashCode");
    debugPrint('Updated inventory cart: $_inventoryCart');

    if (!_inventoryOrder.contains(itemId)) {
      _inventoryOrder.add(itemId);
    }

    notifyListeners();
  }


  void removeItem(String itemId) {
  if (_inventoryCart.containsKey(itemId)) {
    _inventoryCart[itemId] = _inventoryCart[itemId]! - 1;

    if (_inventoryCart[itemId]! <= 0) {
      _inventoryCart.remove(itemId);
      _inventoryOrder.remove(itemId);
    }

    notifyListeners();
  } else {
    debugPrint('Item with Id $itemId not found in cart.');
  }
}


  String serializeInventoryCart(Map<String, int> inventoryCart, String terminalId) {
  final merchantId = merchant.id;
  final List<Map<String, dynamic>> cartItems = inventoryCart.entries.map((entry) {
    return {
      "itemId": int.parse(entry.key),
      "quantity": entry.value,
    };
  }).toList();

  final String merchantIdWithTerminal = "$merchantId$terminalId";

  final Map<String, dynamic> result = {
    "id": merchantIdWithTerminal,
    "order": cartItems,
  };

  return jsonEncode(result);
}


  // Setters for the merchant object
  void setMerchant(Merchant newMerchant) {
    merchant = newMerchant;
    notifyListeners(); // Notify listeners of the change
  }

  // Add a item to the map
  void setItems(Item item) {
    _items[item.itemId] = item;
    notifyListeners(); // Notify listeners of the change
  }

  // Set categories object
  void setCategories(Categories categories) {
    categories = categories;
    notifyListeners(); // Notify listeners of the change
  }

  Item? getItemById(String itemId) {
    return _items[itemId];
  }

  List<int> getCategoryItems(String categoryTag) {
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