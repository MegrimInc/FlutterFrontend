// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:barzzy/AuthPages/RegisterPages/forgotpw.dart';
import 'package:barzzy/AuthPages/RegisterPages/logincache.dart';

import 'package:barzzy/AuthPages/components/mybutton.dart';
import 'package:barzzy/AuthPages/components/mytextfield.dart';
import 'package:barzzy/Gnav%20Bar/bottombar.dart';
import 'package:barzzy/Terminal/select.dart';
import 'package:barzzy/config.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  //final loginCache2 = LoginCache();

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // TEXT EDITING CONTROLLERS

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  //SIGN USER IN

  void signUserIn() async {
    FocusScope.of(context).unfocus();
    final cacher = LoginCache();
    final url = Uri.parse('${AppConfig.postgresApiBaseUrl}/auth/login-customer');
    final requestBody = jsonEncode({
      'email': emailController.value.text.toLowerCase(),
      'password': passwordController.value.text
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json', 
      },
      body: requestBody,
    );

    if (response.statusCode == 200) {
      debugPrint('login Request successful');
      debugPrint('login Response body: ${response.body}');

      try {
        // Added this: Parse the response body as an integer
        int responseValue = int.parse(response.body);

        // Added this: Proper integer comparison
        if (responseValue > 0) {
          cacher.setEmail(emailController.value.text.toLowerCase());
          cacher.setPW(passwordController.value.text);
          cacher.setSignedIn(true);
          cacher.setUID(responseValue);

          debugPrint("UserLogin");
          // Navigate to AuthPage if responseValue is greater than 0
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const AuthPage()));
        } else {
          debugPrint("BarLogin");

          cacher.setEmail(emailController.value.text.toLowerCase());
          cacher.setPW(passwordController.value.text);
          cacher.setSignedIn(true);
          cacher.setUID(responseValue);

          // Navigate to OrderDisplay if responseValue is 0 or negative
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const BartenderIDScreen()));
        }
      } catch (e) {
        // Handle any parsing or other errors
        debugPrint('Error: $e');
        failure();
      }
    } else {
      debugPrint('login Request failed with status: ${response.statusCode}');
      debugPrint('login Response body: ${response.body}');
      invalidCredentialsMessage();
    }
  }

  void failure() {
    showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
              backgroundColor: Colors.white,
              title: Center(
                  child: Text(
                      'Oopsies. Looks like something went wrong. Please try again.',
                      style: TextStyle(
                        color: Color.fromARGB(255, 30, 30, 30),
                        fontWeight: FontWeight.bold,
                      ))));
        });
  }

  //INVALID CREDENTIALS POP UP

  void invalidCredentialsMessage() {
    showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
              backgroundColor: Colors.white,
              title: Center(
                  child: Text(
                      'Looks like you may have typed in the wrong email or password. Please try again!',
                      style: TextStyle(
                        color: Color.fromARGB(255, 30, 30, 30),
                        fontWeight: FontWeight.bold,
                      ))));
        });
  }

  @override
  Widget build(BuildContext context) {
    final FocusNode emailFocusNode = FocusNode();
    final FocusNode passwordFocusNode = FocusNode();
    final ValueNotifier<bool> isEmailFocused = ValueNotifier<bool>(false);
    final ValueNotifier<bool> isPasswordFocused = ValueNotifier<bool>(false);

    emailFocusNode.addListener(() {
      isEmailFocused.value = emailFocusNode.hasFocus;
    });

    passwordFocusNode.addListener(() {
      isPasswordFocused.value = passwordFocusNode.hasFocus;
    });

    return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
            child: Center(
                child: SingleChildScrollView(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 15),

            Center(
              child: Text(
                'Megrim',
                style: GoogleFonts.megrim(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 35,
                ),
              ),
            ),

            const SizedBox(height: 125),

            //Spacer(flex: 1),

            // USER/EMAIL TEXTFIELD

            MyTextField(
              labeltext: 'Email',
              controller: emailController,
              obscureText: false,
              focusNode: passwordFocusNode,
            ),
            const SizedBox(height: 10),

            // PASSWORD TEXTFIELD

            MyTextField(
              labeltext: 'Password',
              controller: passwordController,
              obscureText: true,
              focusNode: emailFocusNode,
            ),
            const SizedBox(height: 10),

            // FORGOT PASSWORD

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const ForgotPassword()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),

          const SizedBox(height: 25),


            // SIGN IN

            MyButton(text: 'Sign In', onTap: signUserIn),

            const SizedBox(height: 25),

            const SizedBox(height: 30),

            const SizedBox(height: 50),

            // NOT A MEMBER REGISTER NOW

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Not a member?',
                  style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: widget.onTap,
                child: const Text('Register',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ])
          ]),
        ))));
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }
}
