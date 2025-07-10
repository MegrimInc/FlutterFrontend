// ignore_for_file: use_build_context_synchronously

import 'package:megrim/UI/AuthPages/RegisterPages/logincache.dart';
import 'package:megrim/DTO/customerorder.dart';
import 'package:megrim/Backend/database.dart';
import 'package:megrim/config.dart';

import 'package:megrim/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:convert';

class Websocket extends ChangeNotifier {
  final String url = '${AppConfig.redisWsBaseUrl}/orders';
  WebSocketChannel? _channel;
  int _reconnectAttempts = 0;
  final LocalDatabase localDatabase;
  final Map<int, Map<int, int>> _createdOrderMerchantIds = {};
  bool _isConnected = false;
  final GlobalKey<NavigatorState> navigatorKey;
  bool isLoading = false;

  Websocket(BuildContext context, this.navigatorKey)
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
                  _handleUpdateResponse(data);
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
    final customerId = await loginCache.getUID();
    final deviceToken = await loginCache.getDeviceToken();

    try {
      if (_channel != null) {
        final message = {
          "action": "refresh",
          "customerId": customerId,
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

  void sendArriveMessage(int merchantId, int employeeId) async {
    try {
      // Fetch customerId from LoginCache
      final loginCache =
          Provider.of<LoginCache>(navigatorKey.currentContext!, listen: false);
      final customerId = await loginCache.getUID();

      // Ensure WebSocket connection is active
      if (_channel != null) {
        // Create the message
        final message = {
          "action": "arrive",
          "customerId": customerId,
          "merchantId": merchantId,
          "employeeId": employeeId,
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

      localDatabase.addOrUpdateOrderForMerchant(customerOrder);

      _createdOrderMerchantIds.putIfAbsent(customerOrder.merchantId, () => {});
      _createdOrderMerchantIds[customerOrder.merchantId]![
          customerOrder.employeeId] = customerOrder.timestamp;

      // Print statement to confirm addition
      debugPrint(
          'CustomerOrder added to LocalDatabase: ${customerOrder.merchantId}');

      setLoading(false);

      try {
        await sendGetPoints();
        debugPrint('sendGetPoints triggered successfully.');
      } catch (e) {
        debugPrint('Error while handling update response: $e');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error while creating CustomerOrder: $e');
    }
  }

  void _handleUpdateResponse(Map<String, dynamic> data) async {
    try {
      final customerOrder = CustomerOrder.fromJson(data);

      // If status is delivered or canceled, remove from the order map
      if (customerOrder.status == "delivered" ||
          customerOrder.status == "canceled") {
        debugPrint(
            'Order ${customerOrder.merchantId} removed due to status: ${customerOrder.status}');

        localDatabase.removeOrderForMerchantAndEmployee(
          customerOrder.merchantId,
          customerOrder.employeeId,
        );

        if (_createdOrderMerchantIds.containsKey(customerOrder.merchantId)) {
          _createdOrderMerchantIds[customerOrder.merchantId]
              ?.remove(customerOrder.employeeId);
          if (_createdOrderMerchantIds[customerOrder.merchantId]?.isEmpty ??
              true) {
            _createdOrderMerchantIds.remove(customerOrder.merchantId);
          }
        }
      } else {
        // Otherwise, add or update order as usual
        localDatabase.addOrUpdateOrderForMerchant(customerOrder);
        _createdOrderMerchantIds.putIfAbsent(
            customerOrder.merchantId, () => {});
        _createdOrderMerchantIds[customerOrder.merchantId]![
            customerOrder.employeeId] = customerOrder.timestamp;
        debugPrint(
            'Order ${customerOrder.merchantId} updated/added with status: ${customerOrder.status}');
      }

      setLoading(false);

      try {
        await sendGetPoints();
        debugPrint('sendGetPoints triggered successfully.');
      } catch (e) {
        debugPrint('Error while handling update response: $e');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error while processing update response: $e');
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

  // Method to retrieve the list of merchantIds for created orders
  List<MapEntry<int, int>> getOrders() {
    final List<MapEntry<int, int>> orders = [];
    _createdOrderMerchantIds.forEach((merchantId, empMap) {
      empMap.forEach((employeeId, _) {
        orders.add(MapEntry(merchantId, employeeId));
      });
    });
    // Sort by timestamp (descending)
    orders.sort((a, b) {
      final tA = _createdOrderMerchantIds[a.key]![a.value]!;
      final tB = _createdOrderMerchantIds[b.key]![b.value]!;
      return tB.compareTo(tA);
    });
    return orders;
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
    final database =
        Provider.of<LocalDatabase>(navigatorKey.currentContext!, listen: false);

    // Check if `ordersData` is a list or a single object
    final List<dynamic> orders = ordersData is List<dynamic>
        ? ordersData // Already a list
        : [ordersData]; // Wrap single object in a list

    for (var order in orders) {
      final merchantId = order['merchantId']; // Extract merchantId as a string
      if (merchantId != null) {
        debugPrint('Fetching tags and items for merchantId: $merchantId');
        await database.fetchCategoriesAndItems(merchantId); // Trigger the fetch
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
