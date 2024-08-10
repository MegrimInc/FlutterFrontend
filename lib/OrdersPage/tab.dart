import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class Hierarchy with ChangeNotifier {
  final int userId;
  static const _tabKey = 'tabs';
  Set<Map<String, dynamic>> _orders = {}; // Use a Set to ensure uniqueness

  Hierarchy(this.userId) {
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final orders = prefs.getStringList(_tabKey) ?? [];
    _orders = orders
        .map((order) => jsonDecode(order) as Map<String, dynamic>)
        .toSet(); // Cast to Map<String, dynamic> and convert to Set
    notifyListeners();
  }

  Future<void> addOrder(int barId, int userId, Set<int> drinkIds) async {
   
    // Generate a UUID for the orderId
    final orderId = const Uuid().v4();

    // Create the order
    final Map<String, dynamic> order = {
      'barId': barId,
      'userId': userId,
      'orderId': orderId,
      'drinkIds': drinkIds.toList(),
    };

     

    // Store the order locally
    _orders.add(order);
    await _saveOrders();
    debugPrint('hello lets see this not work');

    // Send the order to the server
    await _sendOrderToServer(order);
    
  }

  Future<void> _saveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final orders = _orders.map((order) => jsonEncode(order)).toList();
    await prefs.setStringList(_tabKey, orders);
  }

  Future<void> _sendOrderToServer(Map<String, dynamic> order) async {
    final url = Uri.parse('https://www.barzzy.site/hierarchy/create');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(order),
    );

    if (response.statusCode == 200) {
      debugPrint('Order sent successfully: ${response.body}');
    } else {
      debugPrint('Failed to send order: ${response.statusCode}');
      debugPrint('Response: ${response.body}');
    }
  }

  Set<Map<String, dynamic>> getOrders() {
    return _orders;
  }

  Future<void> clearOrders() async {
    _orders.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tabKey);
    notifyListeners();
  }
}
