import 'dart:io';

import 'package:barzzy_app1/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy_app1/AuthPages/components/toggle.dart';
import 'package:barzzy_app1/Terminal/ordersv2-1.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For decoding JSON

class BartenderIDScreen extends StatefulWidget {
  const BartenderIDScreen({super.key});

  @override
  BartenderIDScreenState createState() => BartenderIDScreenState();
}

class BartenderIDScreenState extends State<BartenderIDScreen> {
  bool testing = true;
  final TextEditingController _controller = TextEditingController();
  
  Future<void> _handleSubmit() async {
  final loginData = LoginCache();
  final negativeBarID = await loginData.getUID();
  final barId = -1 * negativeBarID;

  if (_controller.text.isNotEmpty) {
    final String bartenderID = _controller.text;
    final url = 'wss://www.barzzy.site/ws/bartenders';

    try {
      // Attempt to open a WebSocket connection
      final WebSocket socket = await WebSocket.connect(url);
      debugPrint('Connected to WebSocket at $url');

      // Send a message to initialize the bartender session
      final Map<String, dynamic> bartenderLogin = {'action': 'initialize', 'barID': barId, 'bartenderID': bartenderID};
      socket.add(jsonEncode(bartenderLogin));
      
      // Listen for messages
      socket.listen((message) {
        debugPrint('Received: $message');

        // Handle the response from the server
        if (message.contains("Initialization successful")) {
          // Navigate to OrdersPage and pass the bartenderID if successful
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => OrdersPage(bartenderID: bartenderID, barID: barId, socket: socket,)),
            (Route<dynamic> route) => false, // Remove all previous routes
          );
        } else {
          // Show an alert dialog if the response is unsuccessful
          _showAlertDialog(context, "Error", "Failed to initialize: $message");
        }
      });

    } catch (e) {
      // Handle the error
      print('Failed to connect to WebSocket: $e');
      _showAlertDialog(context, "Connection Error", "Could not connect to the server. Please try again.");
    }
  } else {
    // Show a SnackBar with an error message if the text field is empty
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please fill in the BartenderID text field.'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }
}

void _showAlertDialog(BuildContext context, String title, String content) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}


  void _logout() {
    final loginData = LoginCache();
    loginData.setEmail("");
    loginData.setPW("");
    loginData.setSignedIn(false);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginOrRegisterPage()),
      (Route<dynamic> route) => false, // Remove all previous routes
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logged out successfully.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bartender ID Entry'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter Bartender ID',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter alphanumeric code',
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _handleSubmit,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

