import 'dart:convert';
import 'package:barzzy_app1/Extra/auth.dart';
import 'package:http/http.dart' as http;
import 'package:barzzy_app1/AuthPages/components/mybutton.dart';
import 'package:flutter/material.dart';

class RegisterPage2 extends StatefulWidget {
  const RegisterPage2({super.key});

  @override
  State<RegisterPage2> createState() => _RegisterPageState2();
}

class _RegisterPageState2 extends State<RegisterPage2> {

  void acceptTOS() async {
    final url = Uri.parse('https://www.barzzy.site/signup/accept-tos');

    // Create the request body
    final requestBody = jsonEncode({
      'email': 'testuser@example.com',
    });

    try {
      // Send the POST request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json', // Specify that the body is JSON
        },
        body: requestBody,
      );

      // Check the response
      if (response.statusCode == 200) {
        print('TOS Request successful');
        print('TOS Response body: ${response.body}');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthPage()),
        );
      } else {
        print('TOS Request failed with status: ${response.statusCode}');
        print('TOS Response body: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
      failure();
    }
  }

  void failure() {
    showDialog(
      context: context,
      builder: (context) {
        return const AlertDialog(
          backgroundColor: Color.fromARGB(255, 255, 190, 68),
          title: Center(
            child: Text(
              'Something went wrong. Please try again later.',
              style: TextStyle(
                color: Color.fromARGB(255, 30, 30, 30),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Barzzy Terms of Services',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w200,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0, // Removes elevation to prevent color change on scroll
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Ensures left alignment for body text
            children: [
              const SizedBox(height: 25),

              // Centered Title
              const Center(
                child: Text(
                  '1. Introduction\n',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                ),
              ),
              const Text(
                'Welcome to Barzzy! By using our application, you agree to these Terms of Service. Please read them carefully.\n\n',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),

              // Centered Title
              const Center(
                child: Text(
                  '2. Eligibility\n',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                ),
              ),
              const Text(
                'You must be at least 21 years old to use our services. By using the application, you confirm that you meet this age requirement.\n\n',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),

              // Centered Title
              const Center(
                child: Text(
                  '3. Services Provided\n',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                ),
              ),
              const Text(
                'Barzzy allows users to order alcoholic drinks at participating nightclubs, pubs, and bars. Please note that as of now, our application does not support any form of payment transactions.\n\n',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),

              // Repeat the same pattern for other sections

              const SizedBox(height: 100),

              // Button
              MyButton(
                text: 'I have read and agree to the Terms of Services',
                onTap: () {
                  acceptTOS();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
