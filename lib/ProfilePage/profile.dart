import 'package:barzzy_app1/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy_app1/AuthPages/components/toggle.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Add your clearSharedPrefs function here
  void clearSharedPrefs() {
    final loginData = LoginCache();
    loginData.setEmail("");
    loginData.setPW("");
    loginData.setSignedIn(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red, // Logout button color
        onPressed: () {
          clearSharedPrefs(); // Call the function when logging out
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginOrRegisterPage()), // Assuming you have this page elsewhere
            (Route<dynamic> route) => false, // Remove all previous routes
          );
        },
        child: const Icon(Icons.exit_to_app, color: Colors.white), // Icon for logout
      ),
    );
  }
}
