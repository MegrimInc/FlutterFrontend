import 'package:barzzy_app1/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy_app1/Backend/activeorder.dart';
import 'package:barzzy_app1/Backend/localdatabase.dart';
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
              debugPrint('Message type received: "$messageType"');

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

                case 'delete':
                  debugPrint('Delete response received.');
                  final data = decodedMessage['data'];
                  _createOrderResponse(data);
                  break;

                case 'error':
                  debugPrint('error response received.');
                  final String errorMessage = decodedMessage['message'];
                  _handleError(context, errorMessage);
                  break;

                case 'update':
                  debugPrint('Update response received.');
                  final data = decodedMessage['data'];
                  _handleUpdateResponse(data); // Use the new method for updates
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
      } else {
        debugPrint('Failed to send order: WebSocket is not connected');
      }
    } catch (e) {
      debugPrint('Error while sending order: $e');
    }
  }

// Future<void> showNotification(String status, String claimer) async {
//   String notificationMessage;

//   // Determine the notification message based on the status and claimer
//   if (status == 'unready') {
//     if (claimer.isEmpty) {
//       notificationMessage = 'Your order has been unclaimed.';
//     } else {
//       notificationMessage = 'Your order has been claimed.';
//     }
//   } else if (status == 'ready') {
//     notificationMessage = 'Your order is now ready.';
//   } else if (status == 'delivered') {
//     notificationMessage = 'Your order has been delivered.';
//   } else {
//     // Handle any other status if needed, or return if there's nothing to notify
//     return;
//   }

//   const AndroidNotificationDetails androidNotificationDetails =
//       AndroidNotificationDetails(
//     'your_channel_id', // channel ID
//     'your_channel_name', // channel name
//     channelDescription: 'your_channel_description', // channel description
//     importance: Importance.max,
//     priority: Priority.high,
//     ticker: 'ticker',
//   );

//   const DarwinNotificationDetails darwinNotificationDetails =
//       DarwinNotificationDetails();

//   const NotificationDetails platformChannelSpecifics = NotificationDetails(
//     android: androidNotificationDetails,
//     iOS: darwinNotificationDetails,
//   );

//   await flutterLocalNotificationsPlugin.show(
//     0, // Notification ID
//     'Order Status Change', // Notification title
//     notificationMessage, // Notification body
//     platformChannelSpecifics, // Notification details specific to each platform
//     payload: 'pickup', // Payload to pass when the notification is tapped
//   );
// }


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
      debugPrint(
          'CustomerOrder added to LocalDatabase: ${customerOrder.barId}');
    } catch (e) {
      debugPrint('Error while creating CustomerOrder: $e');
    }
  }

  // Method to handle update responses and send notifications
void _handleUpdateResponse(Map<String, dynamic> data) async {
  // Call createOrderResponse to handle the data processing
  _createOrderResponse(data);

  try {
    // Extract the status and claimer from the data
    final String status = data['status'];
    final String claimer = data['claimer'] ?? '';

    // Send a notification with both status and claimer
    //await showNotification(status, claimer);
  } catch (e) {
    debugPrint('Error while handling update response: $e');
  }
}

  void cancelOrder(int barId, int userId) {
    try {
      if (_channel != null) {
        final message = {
          "action": "delete",
          "barId": barId,
          "userId": userId,
        };
        final jsonMessage = jsonEncode(message); // Encode message to JSON
        debugPrint('Sending cancel order message: $jsonMessage');
        _channel!.sink.add(jsonMessage); // Send the JSON encoded string
        debugPrint('Cancel order message sent.');
      } else {
        debugPrint(
            'Failed to send cancel order message: WebSocket is not connected');
      }
    } catch (e) {
      debugPrint('Error while sending cancel order message: $e');
    }
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
          backgroundColor: Colors.black87,
          title: const Row(
            children: [
              SizedBox(width: 75),
              Icon(Icons.error_outline, color: Colors.redAccent),
              SizedBox(width: 5),
              Text(
                'Oops :/',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          content: Text(
            errorMessage,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
          ],
        );
      },
    );
  }

  // Method to retrieve the list of barIds for created orders
  List<String> getOrders() {
    // Return the list of bar IDs sorted by timestamp in descending order
    return _createdOrderBarIds.keys.toList()
      ..sort(
          (a, b) => _createdOrderBarIds[b]!.compareTo(_createdOrderBarIds[a]!));
  }

  bool get isConnected => _isConnected;
}
