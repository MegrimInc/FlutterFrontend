import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class Hierarchy with ChangeNotifier {
  static const _orderKey = 'orders';
   Map<int, Map<String, String>> _orders = {};
  WebSocketChannel? _channel;

  Hierarchy() {
    _loadOrders();
  }

   Future<void> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final orders = prefs.getString(_orderKey) ?? '{}';
    final Map<String, dynamic> decodedOrders = jsonDecode(orders);
    _orders = decodedOrders.map((key, value) => MapEntry(int.parse(key), Map<String, String>.from(value)));
    notifyListeners();
  }

  Future<bool> addOrder(int barId, int userId, Map<int, int> drinkQuantities) async {
  //Check if there's already an order for this barId
  if (_orders.containsKey(barId)) {
    debugPrint('Order already exists for barId: $barId');
    return false; // Prevent placing another order at the same bar
  }

  // Generate a UUID for the orderId
  final orderId = const Uuid().v4();



  // Convert drinkQuantities to use string keys
    final Map<String, int> stringKeyedDrinkQuantities = 
      drinkQuantities.map((key, value) => MapEntry(key.toString(), value));

    final Map<String, dynamic> order = {
      'barId': barId,
      'userId': userId,
      'orderId': orderId,
      'drinkQuantities': stringKeyedDrinkQuantities,
    };



  // Send the order to the server
  final success = await _sendOrderToServer(order);

  if (success) {
    // Establish WebSocket connection after successful order submission
    _establishWebSocketConnection(barId, userId, orderId);

    // Store the order locally only if the server response is successful
    _orders[barId] = {
      'userId': userId.toString(),
      'orderId': orderId,
    };
    await _saveOrders();
    return true;
  } 
  else {
    return false;
  }
}


  Future<bool> _sendOrderToServer(Map<String, dynamic> order) async {
  final url = Uri.parse('https://www.barzzy.site/hierarchy/create');

  try {


   

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(order)
    );

    debugPrint('Response status code: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    // Check the response status and body
    if (response.statusCode == 200) {
      debugPrint('Order sent successfully: ${response.body}');
      return true;
    } else {
      debugPrint('Failed to send order: ${response.statusCode}');
      debugPrint('Response: ${response.body}');
      return false;
    }
  } catch (e) {
    debugPrint('Error sending order: $e');
    return false;
  }
}


  void _establishWebSocketConnection(int barId, int userId, String orderId) {
    final wsUrl = Uri.parse('wss://www.barzzy.site/ws/hierarchy?barId=$barId&userId=$userId&orderId=$orderId');


    // Establish WebSocket connection
    _channel = WebSocketChannel.connect(wsUrl);

    // Listen for updates from the server
    _channel?.stream.listen((data) {
      debugPrint('Received WebSocket message: $data');

      // Handle the update (e.g., parse the message and update UI or notify listeners)
      final response = jsonDecode(data);
      _handleOrderUpdate(response);
    }, onError: (error) {
      debugPrint('WebSocket error: $error');
    }, onDone: () {
      debugPrint('WebSocket connection closed');
    });
  }

  void _handleOrderUpdate(Map<String, dynamic> response) {
    // Handle the response (e.g., update order status)
    // This is where you can update the UI or notify listeners based on the received update
    // Example: Check if the status of an order has changed and act accordingly
    final orderId = response['orderId'];
    final newStatus = response['status'];

    debugPrint('Order $orderId updated to status $newStatus');

    // Update local order state if necessary
    // notifyListeners();
  }

  @override
  void dispose() {
    // Close WebSocket connection when no longer needed
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> clearOrders() async {
  _orders.clear(); // Clear the in-memory orders
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_orderKey); // Remove the orders from SharedPreferences
  debugPrint('Orders after clearing: $_orders'); // Confirm orders are cleared
  notifyListeners(); // Notify listeners to update the UI
}

  Map<int, Map<String, String>> getOrders() {
    return _orders;
  }

 Future<void> _saveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_orderKey, jsonEncode(_orders));
  }
 
}
