/*import 'package:barzzy_app1/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy_app1/Backend/activeorder.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:convert';

class TerminalConnection extends ChangeNotifier {
  final String url = 'wss://www.barzzy.site/ws/bartenders';
  WebSocketChannel? _channel;
  int _reconnectAttempts = 0;
  bool _isConnected = false;

  TerminalConnection(BuildContext context);

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

 

  bool get isConnected => _isConnected;
}
*/