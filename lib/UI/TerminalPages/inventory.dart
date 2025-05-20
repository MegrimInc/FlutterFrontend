import 'dart:convert';

import 'package:barzzy/DTO/merchant.dart';
import 'package:barzzy/DTO/category.dart';
import 'package:barzzy/DTO/item.dart';
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
  final Map<int, Item> _items = {};
  final Map<int, Category> _categoriesById = {};
  final Map<String, List<int>> _categoryItemMap = {};
  final Map<int, int> _inventoryCart = {};
  final List<int> _inventoryOrder = [];
  String _selectedCategory = '';

  Future<void> fetchMerchantDetails(int merchantId) async {
    
    try {
    
      final response = await http.get(Uri.parse('${AppConfig.postgresApiBaseUrl}/customer/$merchantId'));
      //debugPrint("Received response with status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("Response data: $data");

        setMerchant(Merchant.fromJson(data));
        //debugPrint("Parsed merchant object: $merchant");

        await fetchInventoryByMerchant(merchantId);
      } else {
        throw Exception(
            "Failed to fetch merchant details. Status: ${response.statusCode}");
      }
    } catch (error) {
      debugPrint("Error fetching merchant details: $error");
    }
  }

  

Future<void> fetchInventoryByMerchant(int merchantId) async {
  final response = await http.get(
    Uri.parse('${AppConfig.postgresApiBaseUrl}/customer/getInventoryByMerchant/$merchantId'),
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> json = jsonDecode(response.body);
    final List<dynamic> itemJsonList = json['items'];
    final List<dynamic> categoryJsonList = json['categories'];

    final Map<String, List<int>> tempCategoryMap = {};

    // Load categories into the internal map
    _categoriesById.clear();
    for (var categoryJson in categoryJsonList) {
      final category = Category(
        categoryId: categoryJson['categoryId'],
        name: categoryJson['name'],
      );
      _categoriesById[category.categoryId] = category;
    }

    // Process items
    _items.clear();
    for (var itemJson in itemJsonList) {
      final item = Item.fromJson(itemJson);
      setItem(item); // add to _items map

      for (int categoryId in item.categories) {
        final categoryName = _categoriesById[categoryId]?.name;
        if (categoryName != null) {
          tempCategoryMap.putIfAbsent(categoryName, () => []).add(item.itemId);
        }
      }
    }

    _categoryItemMap.clear();
    _categoryItemMap.addAll(tempCategoryMap);

    if (_categoryItemMap.isNotEmpty) {
  _selectedCategory = _categoryItemMap.keys.first;
}

    notifyListeners();
  } else {
    debugPrint('Failed to fetch inventory. Status: ${response.statusCode}');
  }
}

  void addItem(int itemId) {
  
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


  void removeItem(int itemId) {
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


  String serializeInventoryCart(Map<int, int> inventoryCart, String terminalId) {
  final merchantId = merchant.merchantId;
  final List<Map<String, dynamic>> cartItems = inventoryCart.entries.map((entry) {
    return {
      "itemId": entry.key,
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

  void setItem(Item item) {
    _items[item.itemId] = item;
    notifyListeners();
  }

  void setCategoriesList(List<Category> categories) {
    for (final category in categories) {
      _categoriesById[category.categoryId] = category;
    }
    notifyListeners();
  }

  Item? getItemById(int itemId) {
    return _items[itemId];
  }

  List<int> getCategoryItems(String categoryName) => _categoryItemMap[categoryName] ?? [];

  Map<int, int> get inventoryCart => _inventoryCart;

  String get selectedCategory => _selectedCategory;

  List<int> get inventoryOrder => _inventoryOrder;

  // Method to set the selected category
  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners(); // Notify widgets about the change
  }

  List<String> get allCategoryNames => _categoryItemMap.keys.toList();

  void clearInventory() {
    _inventoryCart.clear();
    _inventoryOrder.clear();
    notifyListeners(); // Notify UI to refresh only when necessary
  }
}