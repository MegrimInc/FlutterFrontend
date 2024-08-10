import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class Hierarchy with ChangeNotifier {
  static const _tabKey = 'tabs';
  Set<Map<String, dynamic>> _orders = {}; // Use a Set to ensure uniqueness
  WebSocketChannel? _channel;

  Hierarchy() {
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
    final success = await _sendOrderToServer(order);

    if (success) {
      // Establish WebSocket connection after successful order submission
      _establishWebSocketConnection(barId, userId, orderId);
    }
  }

  Future<void> _saveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final orders = _orders.map((order) => jsonEncode(order)).toList();
    await prefs.setStringList(_tabKey, orders);
  }

  Future<bool> _sendOrderToServer(Map<String, dynamic> order) async {
    final url = Uri.parse('https://www.barzzy.site/hierarchy/create');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(order),
      );

      if (response.statusCode == 200) {
        debugPrint('Order sent successfully: ${response.body}');
        return true; // Return true if the order was successfully sent
      } else {
        debugPrint('Failed to send order: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return false; // Return false if the order failed to send
      }
    } catch (e) {
      debugPrint('Error sending order: $e');
      return false; // Return false if there was an error in sending the order
    }
  }

  void _establishWebSocketConnection(int barId, int userId, String orderId) {
    final wsUrl = Uri.parse('wss://www.barzzy.site/ws/hierarchy');

    // Establish WebSocket connection
    _channel = WebSocketChannel.connect(wsUrl);

    // Send initial message with identifiers
    final message = jsonEncode({
      'barId': barId,
      'userId': userId,
      'orderId': orderId,
    });
    _channel?.sink.add(message);

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
