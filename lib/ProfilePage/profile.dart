import 'dart:convert';
import 'package:barzzy/OrdersPage/hierarchy.dart';
import 'package:barzzy/Backend/localdatabase.dart';
import 'package:barzzy/main.dart';
import 'package:flutter/material.dart';
import 'package:barzzy/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy/AuthPages/components/toggle.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Variables to store user information
  String email = '';
  String password = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // Function to load user information from shared preferences
  void _loadUserInfo() async {
    final loginData = LoginCache();
    final loadedEmail = await loginData.getEmail();
    final loadedPassword = await loginData.getPW();

    setState(() {
      email = loadedEmail;
      password = loadedPassword;
    });
  }

  // Function to clear shared preferences and log out
  void clearSharedPrefs() {
    final localDatabase = Provider.of<LocalDatabase>(context, listen: false);
    final loginData = LoginCache();
    final hierarchy = Provider.of<Hierarchy>(context, listen: false);
    loginData.setEmail("");
    loginData.setPW("");
    loginData.setUID(0);  
    loginData.setSignedIn(false);
    hierarchy.disconnect(); 
    localDatabase.clearOrders();
  }

  // Function to delete user account and log out
  Future<void> deleteAccount() async {
    final response = await http.post(
      Uri.parse('https://www.barzzy.site/newsignup/deleteaccount'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      clearSharedPrefs(); // Clear preferences if account deletion is successful
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginOrRegisterPage()),
        (route) => false,
      );
    } else {
      debugPrint('Error: ${response.statusCode}'); // Print error status code for debugging
      debugPrint('Error body: ${response.body}'); // Print error body for debugging

      // Use the global navigator key to show the SnackBar
      final snackBarContext = navigatorKey.currentContext;

      if (snackBarContext != null) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(snackBarContext).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again later.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        debugPrint('Error: Unable to show SnackBar. Context is null.');
      }
    }
  }

  // Helper function to mask password with asterisks
  String _maskPassword(String password) {
    return '*' * password.length; // Replace password with asterisks
  }

  // Show confirmation dialog
  void showConfirmationDialog(BuildContext context, String actionType, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  actionType == 'Log Out' ? Icons.exit_to_app : Icons.delete_forever,
                  color: Colors.black,
                ),
                const SizedBox(width: 10),
                Text(
                  actionType == 'Log Out' ? 'Confirm Logout' : 'Confirm Delete',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
          content: Text(
            actionType == 'Log Out'
                ? 'Are you sure you want to log out?'
                : 'Are you sure you want to delete your account?',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Cancel',
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
            const SizedBox(width: 10),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog first
                onConfirm(); // Call the confirmation action
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             
            const SizedBox(height: 75),
                  const Center(
                    child: Icon(
                     Icons.person,
                      size: 100, // Adjust the size as needed
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Padding(
                    padding:  EdgeInsets.only(left: 25.0),
                    child: Text(
                      'My Info',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

              const Divider(color: Colors.white54, thickness: 1),
              const SizedBox(height: 20),
              _buildInfoSection('Email', email),
              const SizedBox(height: 20),
              _buildInfoSection('Password', _maskPassword(password)),
              const Divider(color: Colors.white54, thickness: 1), // Divider below password
              const SizedBox(height: 20),
              
              // Delete Account section
              _buildActionSection(
                'Delete Account',
                Icons.delete_forever,
                Colors.redAccent,
                () {
                  showConfirmationDialog(
                    context,
                    'Delete Account',
                    deleteAccount,
                  );
                },
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white54, thickness: 1), // Divider below delete account
              const SizedBox(height: 20),

              // Log Out section
              _buildActionSection(
                'Log Out',
                Icons.exit_to_app,
                Colors.white,
                () {
                  showConfirmationDialog(
                    context,
                    'Log Out',
                    () {
                      clearSharedPrefs();
                      navigatorKey.currentState?.pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginOrRegisterPage()),
                        (route) => false,
                      );
                    },
                  );
                },
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  // Function to build the information section with title above the value
  Widget _buildInfoSection(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Function to build action section with icons and labels
  Widget _buildActionSection(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}