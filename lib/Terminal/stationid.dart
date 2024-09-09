// ignore_for_file: use_build_context_synchronously

import 'package:barzzy_app1/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy_app1/AuthPages/components/toggle.dart';
import 'package:barzzy_app1/Terminal/terminal.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BartenderIDScreen extends StatefulWidget {
  const BartenderIDScreen({super.key});

  @override
  BartenderIDScreenState createState() => BartenderIDScreenState();
}

class BartenderIDScreenState extends State<BartenderIDScreen> {
  final TextEditingController _controller = TextEditingController();
  final ValueNotifier<bool> isFocused = ValueNotifier<bool>(false);
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      isFocused.value = focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    isFocused.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final loginData = LoginCache();
    final negativeBarID = await loginData.getUID();
    final barId = -1 * negativeBarID;

    if (_controller.text.isNotEmpty) {
      final String bartenderID = _controller.text;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => OrdersPage(
                  bartenderID: bartenderID.toUpperCase(),
                  barID: barId,
                )),
        (Route<dynamic> route) => false, // Remove all previous routes
      );
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
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginOrRegisterPage()),
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
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox.shrink(), // Empty space to balance the Row
                
                IconButton(
                  icon: const Icon(Icons.exit_to_app),
                  onPressed: _logout,
                  color: Colors.grey,
                  iconSize: 27.5,
                ),
              ],
            ),
            const SizedBox(height: 75),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
              
                Text(
                  'B A R Z Z Y',
                  style: GoogleFonts.megrim(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
              ],
            ),
            const SizedBox(height: 100),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Enter Station Name',
                style: TextStyle(
                  fontSize: 17.5,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<bool>(
              valueListenable: isFocused,
              builder: (context, focused, child) {
                return TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: const BorderSide(
                        color: Color.fromARGB(255, 60, 60, 60),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    fillColor: focused
                        ? Colors.black
                        : const Color.fromARGB(255, 60, 60, 60),
                    filled: true,
                  ),
                );
              },
            ),
            const SizedBox(height: 75),
            ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black, // Button background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15), // Rounded corners
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 75, vertical: 15), // Button padding
              ),
              child: Text('S u B m I T',
              style: GoogleFonts.megrim(
                textStyle: const TextStyle( 
                fontSize: 25, 
                color: Colors.white, 
                fontWeight: FontWeight.bold)),)
            ),
          ],
        ),
      ),
    );
  }
}