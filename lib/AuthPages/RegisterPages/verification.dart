import 'package:barzzy_app1/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy_app1/AuthPages/RegisterPages/tos.dart';

import 'package:barzzy_app1/AuthPages/components/mybutton.dart';
import 'package:barzzy_app1/AuthPages/components/mytextfield.dart';
import 'package:barzzy_app1/Extra/sessionid.dart';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:provider/provider.dart'; // For jsonEncode

class RegisterPage11 extends StatefulWidget {
  final void Function()? onTap;
  final String message;

  const RegisterPage11({super.key, this.onTap, required this.message});

  @override
  State<RegisterPage11> createState() => _RegisterPageState11();
}

class _RegisterPageState11 extends State<RegisterPage11> {
  final verificationCode = TextEditingController();
  final loginCache4 = LoginCache();

  void attemptVerification() async {
    // Define the URL
    final url = Uri.parse('https://www.barzzy.site/signup/verify');


    // Create the request body
    final requestBody = jsonEncode({
      'email': await loginCache4.getEmail(),
      'verificationCode': verificationCode.value.text,
      'password': await loginCache4.getPW(),
      'firstName': await loginCache4.getFN(),
      'lastName': await loginCache4.getLN()
    });

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
      print('Request successful');
      print('Response body: ${response.body}');
      int uid = int.parse(response.body);
      if (uid == 0) {
        incorrect();
      } else if (uid > 0) {
        final loginCache4 = LoginCache();
        loginCache4.setUID(uid);
         // Update the UserProvider with the new userId
      // ignore: use_build_context_synchronously
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.setUserId(uid);
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const RegisterPage2()));
      } else {
        failure();
      }
    } else {
      print('Request failed with status: ${response.statusCode}');
      print('Response body: ${response.body}');
      failure();
    }
  }

  void incorrect() {
    showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
              backgroundColor: Colors.white,
              title: Center(
                  child: Text('Incorrect...',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ))));
        });
  }

  void failure() {
    showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
              backgroundColor: Colors.white,
              title: Center(
                  child: Text('Incorrect Code...',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ))));
        });
  }

  @override
  Widget build(BuildContext context) {
    final FocusNode firstNameNode = FocusNode();
    final FocusNode lastNameNode = FocusNode();
    final ValueNotifier<bool> isFirstNameFocused = ValueNotifier<bool>(false);
    final ValueNotifier<bool> isLastNameFocused = ValueNotifier<bool>(false);

    firstNameNode.addListener(() {
      isFirstNameFocused.value = firstNameNode.hasFocus;
    });

    lastNameNode.addListener(() {
      isLastNameFocused.value = lastNameNode.hasFocus;
    });

    return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
            child: Center(
                child: SingleChildScrollView(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 75),

            // ICONS: NEEDS TO BE CHANGED TO BARZZY LOGO
            const Icon(Icons.abc_outlined,
                size: 100, color: Color.fromARGB(255, 15, 15, 15)),
            const SizedBox(height: 100),

            // USER/EMAIL TEXTFIELD

            MyTextField(
              labeltext: widget.message,
              controller: verificationCode,
              obscureText: false,
            ),

            MyButton(
              text: 'Confirm',
              onTap: attemptVerification,
            ),
            const SizedBox(height: 25),

            const SizedBox(height: 30),
            const SizedBox(height: 50),
          ]),
        ))));
  }
}
