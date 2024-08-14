import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:ntp/ntp.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class Hierarchy with ChangeNotifier {
  static const _orderKey = 'orders';
  Map<int, Map<String, dynamic>> _orders = {};
  WebSocketChannel? _channel;

  Hierarchy() {
    _loadOrders();
    notifyListeners();
  }

  Future<void> _loadOrders() async {
  final prefs = await SharedPreferences.getInstance();
  final orders = prefs.getString(_orderKey) ?? '{}';
  debugPrint('Loaded orders from SharedPreferences: $orders');
  final Map<String, dynamic> decodedOrders = jsonDecode(orders);
  _orders = decodedOrders.map((key, value) =>
      MapEntry(int.parse(key), Map<String, dynamic>.from(value.map((k, v) => 
        MapEntry(k, v is String && v.startsWith('{') && v.endsWith('}') ? 
          jsonDecode(v) : v)))));
  debugPrint('Decoded orders: $_orders');
  notifyListeners();
}

  Future<bool> addOrder(
      int barId, int userId, Map<int, int> drinkQuantities) async {
    //Check if there's already an order for this barId
    if (_orders.containsKey(barId)) {
      debugPrint('Order already exists for barId: $barId');
      return false; // Prevent placing another order at the same bar
    }

    // Generate a UUID for the orderId
    final orderId = const Uuid().v4().replaceAll('-', '_');

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

      // Get the current time from NTP
      DateTime ntpTime = await NTP.now();

      // Add the `created_at` field with the NTP time (UTC)
      final Map<String, dynamic> orderWithStatusAndTimestamp = Map.from(order)
        ..['status'] = null
        ..['claimer'] = null
        ..['created_at'] = ntpTime.toIso8601String();

      // Store the order locally only if the server response is successful
      _orders[barId] = orderWithStatusAndTimestamp;
      await _saveOrders();
      return true;
    } else {
      return false;
    }
  }

  Future<bool> _sendOrderToServer(Map<String, dynamic> order) async {
    final url = Uri.parse('https://www.barzzy.site/hierarchy/create');

    try {
      final response = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(order));

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
    final wsUrl = Uri.parse(
        'wss://www.barzzy.site/ws/hierarchy?barId=$barId&userId=$userId&orderId=$orderId');

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
    final barId = response['barId'];
    final orderId = response['orderId'];
    final newStatus = response['status'];
    final newClaimer = response['claimer'];

    debugPrint('Updating order for barId: $barId with new status: $newStatus');

    // Ensure drinkQuantities is properly handled
    final drinkQuantities = Map<String, int>.from(response['drinkQuantities']);

    // Update the order in the _orders map
    if (_orders.containsKey(barId)) {
      // Preserve the existing order details and update the status
      final existingOrder = _orders[barId];
      _orders[barId] = {
        'barId': existingOrder?['barId']?.toString(),
        'userId': existingOrder?['userId']?.toString(),
        'orderId': existingOrder?['orderId'],
        'status': newStatus,
        'claimer': newClaimer,
        'created_at':
            existingOrder?['created_at'], // Preserve the created_at timestamp
        'drinkQuantities': drinkQuantities,
      };
      debugPrint('Order after update: ${_orders[barId]}');
      notifyListeners(); // Notify listeners to update the UI
      _saveOrders();
    } else {
      debugPrint('No existing order found for barId: $barId');
    }

    debugPrint('Order $orderId updated to status $newStatus');
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
    await _saveOrders();
  }

  Map<int, Map<String, dynamic>> getOrders() {
    return _orders;
  }

  Future<void> _saveOrders() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    // Ensure all nested maps handle null values appropriately
    final sanitizedOrders = _orders.map((key, value) => MapEntry(
          key.toString(), // Convert key to string
          value.map((nestedKey, nestedValue) => MapEntry(
                nestedKey,
                nestedValue is Map ? 
                  json.encode(nestedValue) : // Encode nested maps
                  nestedValue?.toString() ?? '', // Convert other values to string or use empty string for null
              )),
        ));

    // Convert the sanitized orders to JSON string
    final ordersJson = jsonEncode(sanitizedOrders);

    // Print the orders being saved
    debugPrint('Saving orders to SharedPreferences: $ordersJson');

    // Save the orders to SharedPreferences
    await prefs.setString(_orderKey, ordersJson);
    debugPrint('Orders successfully saved to SharedPreferences');
  } catch (e) {
    debugPrint('Error in _saveOrders: $e');
  }
}



  Future<void> clearExpiredOrders() async {
    final DateTime now = await NTP.now(); // Get the current time from NTP
    bool hasCleared = false;

    _orders.removeWhere((barId, order) {
      final DateTime createdAt = DateTime.parse(order['created_at']);
      final Duration difference = now.difference(createdAt);

      debugPrint('Current NTP time: $now');
      debugPrint('Order created_at time: $createdAt');
      debugPrint('Time difference in seconds: ${difference.inSeconds}');

      // Temporarily set expiration time to 10 seconds for testing
      if (difference.inHours >= 24) {
        hasCleared = true;
        debugPrint(
            'Order for barId: $barId is older than 24 hours and will be removed.');
        return true;
      }
      return false;
    });

    if (hasCleared) {
      await _saveOrders(); // Save the updated orders after removal
      notifyListeners(); // Notify listeners to update the UI
    }
  }
}
