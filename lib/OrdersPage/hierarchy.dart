

import 'package:barzzy_app1/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy_app1/Backend/activeorder.dart';
import 'package:barzzy_app1/Backend/localdatabase.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:convert';

class Hierarchy extends ChangeNotifier {
  final String url = 'wss://www.barzzy.site/ws/orders';
  WebSocketChannel? _channel;
  int _reconnectAttempts = 0;
  final LocalDatabase localDatabase;
  final List<String> _createdOrderBarIds = [];
  bool _isConnected = false;
  static const String _prefsKey = 'createdOrderBarIds';
  

  Hierarchy(BuildContext context)
      : localDatabase = Provider.of<LocalDatabase>(context, listen: false)
      {_loadBarIdsFromSharedPreferences();}


  // Establish a WebSocket connection with exponential backoff
  void connect(BuildContext context) {
    if (_channel == null) {
      // Ensure there's no existing connection
      try {
        _channel =
            WebSocketChannel.connect(Uri.parse(url)); // Attempt to connect
        _channel!.stream.listen(
          (message) {
            if (_reconnectAttempts > 0) {
              debugPrint(
                  'Connection successful. Resetting reconnect attempts.');
              _reconnectAttempts =
                  0; // Reset the reconnect attempts on successful connection
            }

            _isConnected = true;

            debugPrint('Received: $message');
            notifyListeners(); // Notify listeners of new messages

            // Here you process the received message
            try {
              // Parse the incoming message as JSON
              final decodedMessage = jsonDecode(message);

              // Extract the messageType from the decoded JSON
              final String messageType = decodedMessage['messageType'];

              switch (messageType) {
                case 'ping':
                  debugPrint('Ping received, sending refresh message.');
                  _sendRefreshMessage(context); // Handle the ping message
                  break;

                case 'refresh':
                  debugPrint('Refresh response received.');
                  // Handle the refresh response if needed
                  // You can also extract the 'data' from the message and use it as needed
                  final data = decodedMessage['data'];
                  _createOrderResponse(data);
                  break;

                case 'create':
                  debugPrint('Create response received.');
                  final data = decodedMessage['data'];
                  _createOrderResponse(
                      data); // Trigger the createOrderResponse method
                  break;


                  case 'update':
                  debugPrint('Update response received.');
                  final data = decodedMessage['data'];
                  _createOrderResponse(
                      data); // Trigger the createOrderResponse method
                  break;


                default:
                  debugPrint('Unknown message type: $messageType');
                  // Handle any other message types or log an error
                  break;
              }
            } catch (e) {
              debugPrint('Error processing message: $e');
            }
          },
          onError: (error) {
            debugPrint('WebSocket error: $error');
            // Optional: Handle diagnostics here, but don't assume the connection is closed
          },
          onDone: () {
            debugPrint(
                'WebSocket connection closed. Close code: ${_channel!.closeCode}, reason: ${_channel!.closeReason}');
            debugPrint('WebSocket connection closed');
            _isConnected = false;
            _attemptReconnect(
                context); // Handle connection loss and attempt reconnection
            notifyListeners();
          },
        );
      } catch (e) {
        // Catch any errors during connection
        debugPrint('Failed to connect: $e');
        _isConnected = false;
        _attemptReconnect(
            context); // Attempt reconnection on connection failure
      }
    }
  }

  // Attempt to reconnect with exponential backoff
  void _attemptReconnect(BuildContext context) {
    _reconnectAttempts++;
    int delay = (1 <<
        (_reconnectAttempts -
            1)); // Exponential backoff: 1, 2, 4, 8, etc. seconds
    debugPrint(
        'Scheduling reconnect attempt $_reconnectAttempts in $delay seconds.');

    Future.delayed(Duration(seconds: delay), () {
      debugPrint('Attempting to reconnect... (Attempt $_reconnectAttempts)');
      _channel = null; // Ensure _channel is null before reconnecting
      connect(context); // Re-attempt the connection
    });
  }

  // Send the "refresh" message over the WebSocket connection

  void _sendRefreshMessage(BuildContext context) async {
    final loginCache = Provider.of<LoginCache>(context, listen: false);
    final userId = await loginCache.getUID();

    try {
      if (_channel != null) {
        final message = {
          "action": "refresh",
          "userId": userId,
        };
        final jsonMessage =
            jsonEncode(message); // Use jsonEncode for proper JSON formatting
        debugPrint('Sending refresh message: $jsonMessage');
        _channel!.sink.add(jsonMessage); // Send the JSON encoded string
        debugPrint('Refresh message sent.');
      } else {
        debugPrint(
            'Failed to send refresh message: WebSocket is not connected');
      }
    } catch (e) {
      debugPrint('Error while sending message: $e');
    }
  }

// Method to send an order
  void createOrder(Map<String, dynamic> order) {
    try {
      if (_channel != null) {
        final jsonOrder = jsonEncode(order); // Convert the order to JSON
        debugPrint('Sending create order: $jsonOrder');
        _channel!.sink.add(jsonOrder); // Send the order over WebSocket
        debugPrint('Order sent.');
      } else {
        debugPrint('Failed to send order: WebSocket is not connected');
      }
    } catch (e) {
      debugPrint('Error while sending order: $e');
    }
  }


  // Method to handle create order responses
void _createOrderResponse(Map<String, dynamic> data) async {
  try {
    // Create a CustomerOrder object using the data from the response
    final customerOrder = CustomerOrder.fromJson(data);
    debugPrint('CustomerOrder created: $customerOrder');

    localDatabase.addOrUpdateOrderForBar(customerOrder);

    // Add the bar ID to the list, ensuring only the 5 most recent IDs are stored
    if (_createdOrderBarIds.contains(customerOrder.barId)) {
      // If the barId already exists, remove it from its current position
      _createdOrderBarIds.remove(customerOrder.barId);
    }
    // Add the barId to the end of the list (most recent)
    _createdOrderBarIds.add(customerOrder.barId);

    // Ensure the list contains only the 5 most recent IDs
    if (_createdOrderBarIds.length > 5) {
      _createdOrderBarIds.removeAt(0); // Remove the oldest ID
    }

     await _saveBarIdsToSharedPreferences();

    // Print statement to confirm addition
    debugPrint('CustomerOrder added to LocalDatabase: ${customerOrder.barId}');
  } catch (e) {
    debugPrint('Error while creating CustomerOrder: $e');
  }
}



// Method to save the list to SharedPreferences
  Future<void> _saveBarIdsToSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _createdOrderBarIds);
  }

  // Method to load the list from SharedPreferences
  Future<void> _loadBarIdsFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final loadedBarIds = prefs.getStringList(_prefsKey);

    if (loadedBarIds != null) {
      _createdOrderBarIds.addAll(loadedBarIds);
    }

    notifyListeners(); // Notify listeners that the data has been loaded
  }

  // Method to retrieve the list of barIds for created orders
  List<String> getOrders() {
    return _createdOrderBarIds;
  }

  bool get isConnected => _isConnected;
}
