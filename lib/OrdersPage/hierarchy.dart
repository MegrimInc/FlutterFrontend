import 'dart:async';
import 'dart:convert';
import 'package:barzzy_app1/Backend/activeorder.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../Backend/localdatabase.dart';

class WebSocketResult {
  final bool success;
  final String message;

  WebSocketResult(this.success, this.message);
}

class Hierarchy with ChangeNotifier {
  final List<int> _activeorders = [];
  WebSocketChannel? _channel;

  Future<WebSocketResult> establishWebSocketConnection(int barId, int userId, Map<int, int> drinkQuantities) async {
  final List<Map<String, dynamic>> drinksList = drinkQuantities.entries.map((entry) {
    return {
      'drinkId': entry.key,
      'quantity': entry.value,
    };
  }).toList();

  final Map<String, dynamic> order = {
    'barId': barId,
    'userId': userId,
    'drinks': drinksList,
  };

  final wsUrl = Uri.parse('wss://www.barzzy.site/ws/orders');

  try {
    _channel = WebSocketChannel.connect(wsUrl);

    final completer = Completer<WebSocketResult>();
    String lastMessage = ""; // Store the last received message

    _channel?.sink.add(jsonEncode(order));

    _channel?.stream.listen((data) async {
      debugPrint('Received WebSocket message: $data');
      lastMessage = data; // Update the last received message

      final response = jsonDecode(data);
      final result = await _handleOrderResponse(response);

      completer.complete(result);
    }, onError: (error) {
      debugPrint('WebSocket error: $error');
      completer.complete(WebSocketResult(false, "Connection error: $error"));
    }, onDone: () {
      debugPrint('WebSocket connection closed');
      if (!completer.isCompleted) {
        // Use the last received message if available, otherwise use a generic message
        completer.complete(WebSocketResult(false, lastMessage.isNotEmpty ? lastMessage : "Connection closed unexpectedly"));
      }
    });

    return completer.future;
  } catch (e) {
    return WebSocketResult(false, "Failed to connect: ${e.toString()}");
  }
}


  Future<WebSocketResult> _handleOrderResponse(Map<String, dynamic> response) async {
    final String messageType = response['messageType']?.toString() ?? 'unknown';
    final String message = response['message']?.toString() ?? 'No message';

    debugPrint('Order response received: $messageType, message: $message');

    if (messageType == 'success') {
      final orderData = response['data'];
      debugPrint('Order data extracted: $orderData');

      final order = CustomerOrder.fromJson(orderData);
      debugPrint('Order object created: ${order.toJson()}');

      // Add or update the order in LocalDatabase
      LocalDatabase().addOrUpdateOrderForBar(order);
       _activeorders.add(orderData['barId']);

      notifyListeners();
      return WebSocketResult(true, "Order processed: $message");
    } else {
      debugPrint('Order response indicates failure: $message');
      return WebSocketResult(false, message);
    }
  }

 List<int> getOrders() {
    return _activeorders;
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}
