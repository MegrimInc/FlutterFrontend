import 'package:barzzy_app1/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy_app1/AuthPages/components/toggle.dart';
import 'package:barzzy_app1/OrdersPage/ordersv2-1.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For decoding JSON

class BartenderIDScreen extends StatefulWidget {
  const BartenderIDScreen({super.key});

  @override
  _BartenderIDScreenState createState() => _BartenderIDScreenState();
}

class _BartenderIDScreenState extends State<BartenderIDScreen> {
  final TextEditingController _controller = TextEditingController();
  
  Future<void> _handleSubmit() async {
    final loginData = LoginCache();
    if (_controller.text.isNotEmpty) {
      final String bartenderID = _controller.text;
      final String email = await loginData.getEmail();
      final String password = await loginData.getPW();

      final Uri url = Uri.parse('https://www.barzzy.site/signup/bartenderIDLogin');

      try {
        final response = await http.get(
          url.replace(queryParameters: {
            'bartenderID': bartenderID,
            'email': email,
            'password': password,
          }),
        );

        if (response.statusCode == 200) {
          // Parse the response if needed
          final responseData = jsonDecode(response.body);

          // Navigate to OrdersPage and pass the bartenderID
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrdersPage(bartenderID: bartenderID),
            ),
          );
        } else {
          // Handle response error (status code other than 200)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to make a connection to the server. Status code: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Handle network or other errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
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

  void _logout() {
    final loginData = LoginCache();
    loginData.setEmail("");
    loginData.setPW("");
    loginData.setSignedIn(false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginOrRegisterPage(),
            ),
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
