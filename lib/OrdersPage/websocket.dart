// ignore_for_file: use_build_context_synchronously

import 'package:barzzy/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy/Backend/customer_order.dart';
import 'package:barzzy/Backend/localdatabase.dart';
import 'package:barzzy/Backend/preferences.dart';
import 'package:barzzy/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:convert';

class Hierarchy extends ChangeNotifier {
  final String url = 'wss://www.barzzy.site/ws/orders';
  WebSocketChannel? _channel;
  int _reconnectAttempts = 0;
  final LocalDatabase localDatabase;
  final Map<String, int> _createdOrderBarIds = {};
  bool _isConnected = false;
  final GlobalKey<NavigatorState> navigatorKey;
  bool isLoading = false;

  Hierarchy(BuildContext context, this.navigatorKey)
      : localDatabase = Provider.of<LocalDatabase>(context, listen: false);

  // Establish a WebSocket connection with exponential backoff
  void connect(BuildContext context) {
    if (_channel == null) {
      // Ensure there's no existing connection
      try {
        _channel =
            WebSocketChannel.connect(Uri.parse(url)); // Attempt to connect
        _channel!.stream.listen(
          (message) async {
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
              debugPrint('Message type received: "$messageType"');

              switch (messageType) {
                case 'ping':
                  debugPrint('Ping received, sending refresh message.');
                  sendRefreshMessage(context); // Handle the ping message
                  break;

                case 'refresh':
                  debugPrint('Refresh response received.');
                  // Handle the refresh response if needed
                  // You can also extract the 'data' from the message and use it as needed
                  final data = decodedMessage['data'];
                  _createOrderResponse(data);
                  await handleCache(data);
                  break;

                case 'create':
                  debugPrint('Create response received.');
                  final data = decodedMessage['data'];
                  _createOrderResponse(
                      data); // Trigger the createOrderResponse method
                  break;

                case 'error':
                  debugPrint('error response received.');
                  final String errorMessage = decodedMessage['message'];
                  _handleError(context, errorMessage);
                   setLoading(false);
                  break;

                case 'update':
                  debugPrint('Update response received.');
                  final data = decodedMessage['data'];
                  _handleUpdateResponse(data); // Use the new method for updates
                  break;

                default:
                  debugPrint('Unknown message type: $messageType');
                   setLoading(false);
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
            _channel = null; // Ensure _channel is null before reconnecting
            _attemptReconnect(
                context); // Handle connection loss and attempt reconnection
            notifyListeners();
          },
        );
      } catch (e) {
        // Catch any errors during connection
        debugPrint('Failed to connect: $e');
        _isConnected = false;
        _channel = null; // Ensure _channel is null before reconnecting
        _attemptReconnect(
            context); // Attempt reconnection on connection failure
        notifyListeners();
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
      connect(context); // Re-attempt the connection
    });
  }

  // Send the "refresh" message over the WebSocket connection

  void sendRefreshMessage(BuildContext context) async {
    final loginCache = Provider.of<LoginCache>(context, listen: false);
    final userId = await loginCache.getUID();
    final deviceToken = await loginCache.getDeviceToken();

    try {
      if (_channel != null) {
        final message = {
          "action": "refresh",
          "userId": userId,
          "deviceToken": deviceToken
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
        setLoading(true);
        debugPrint('isLoading is set to true');
      } else {
        debugPrint('Failed to send order: WebSocket is not connected');
      }
    } catch (e) {
      debugPrint('Error while sending order: $e');
    }
  }

  void sendArriveMessage(int barId) async {
  try {
    // Fetch userId from LoginCache
    final loginCache = Provider.of<LoginCache>(navigatorKey.currentContext!, listen: false);
    final userId = await loginCache.getUID();

    // Ensure WebSocket connection is active
    if (_channel != null) {
      // Create the message
      final message = {
        "action": "arrive",
        "userId": userId,
        "barId": barId,
      };

      // Convert message to JSON and send
      final jsonMessage = jsonEncode(message);
      debugPrint('Sending arrive message: $jsonMessage');
      _channel!.sink.add(jsonMessage);
    } else {
      debugPrint('Failed to send arrive message: WebSocket is not connected');
    }
  } catch (e) {
    debugPrint('Error while sending arrive message: $e');
  }
}

  // Method to handle create order responses
  void _createOrderResponse(Map<String, dynamic> data) async {
    try {
      // Create a CustomerOrder object using the data from the response
      final customerOrder = CustomerOrder.fromJson(data);
      debugPrint('CustomerOrder created: $customerOrder');

      localDatabase.addOrUpdateOrderForBar(customerOrder);
      // Directly update the map with the new timestamp for the barId
      _createdOrderBarIds[customerOrder.barId] = customerOrder.timestamp;

      // Print statement to confirm addition
      debugPrint('CustomerOrder added to LocalDatabase: ${customerOrder.barId}');
      debugPrint('hierarchy localDatabase instance ID: ${localDatabase.hashCode}');
      setLoading(false);
      notifyListeners();
    } catch (e) {
      debugPrint('Error while creating CustomerOrder: $e');
    }
  }


  // Method to handle update responses and send notifications
void _handleUpdateResponse(Map<String, dynamic> data) async {
  // Call createOrderResponse to handle the data processing
  _createOrderResponse(data);

  try {
    // Check if the status in the data is "delivered" or "canceled"
    if (data['status'] == 'delivered' || data['status'] == 'canceled') {
      debugPrint('Status is delivered or canceled. Triggering sendGetRequest2...');
      await sendGetRequest2();
      debugPrint('sendGetRequest2 triggered successfully.');
    }
  } catch (e) {
    debugPrint('Error while handling update response: $e');
  }
}


  void disconnect() {
    if (_channel != null) {
      debugPrint('Closing WebSocket connection.');
      _channel!.sink.close(); // Close the WebSocket connection
      _isConnected = false;
      _channel = null;
      notifyListeners(); // Notify listeners that the connection has been closed
    }
  }

  // Method to retrieve the list of barIds for created orders
  List<String> getOrders() {
    // Return the list of bar IDs sorted by timestamp in descending order
    return _createdOrderBarIds.keys.toList()
      ..sort(
          (a, b) => _createdOrderBarIds[b]!.compareTo(_createdOrderBarIds[a]!));
  }

  void _handleError(BuildContext context, String errorMessage) {
    // Use the global navigator key to get a safe context
    final safeContext = navigatorKey.currentContext;

    if (safeContext == null) {
      //debugPrint('Safe context is null. Cannot show dialog.');
      return;
    }

    //debugPrint('Showing error dialog with safe context: $safeContext');

    showDialog(
      context: safeContext,
      builder: (BuildContext context) {
        HapticFeedback.heavyImpact();
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: const Row(
            children: [
              SizedBox(width: 75),
              Icon(Icons.error_outline, color: Colors.black),
              SizedBox(width: 5),
              Text(
                'Oops :/',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          content: Text(
            errorMessage,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Future<void> handleCache(dynamic ordersData) async {
    final user = Provider.of<User>(navigatorKey.currentContext!, listen: false);

    // Check if `ordersData` is a list or a single object
    final List<dynamic> orders = ordersData is List<dynamic>
        ? ordersData // Already a list
        : [ordersData]; // Wrap single object in a list

    for (var order in orders) {
      final barId = order['barId']?.toString(); // Extract barId as a string
      if (barId != null && barId.isNotEmpty) {
        debugPrint('Fetching tags and drinks for barId: $barId');
        await user.fetchTagsAndDrinks(barId); // Trigger the fetch
      }
    }
  }

  bool get isConnected => _isConnected;

  void setLoading(bool value) {
    if (isLoading != value) {
      isLoading = value;
      notifyListeners();
    }
  }
}
