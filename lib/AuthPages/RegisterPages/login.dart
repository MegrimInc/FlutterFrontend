// ignore_for_file: use_build_context_synchronously


import 'dart:convert';

import 'package:barzzy_app1/AuthPages/RegisterPages/logincache.dart';

import 'package:barzzy_app1/AuthPages/components/mybutton.dart';
import 'package:barzzy_app1/AuthPages/components/mytextfield.dart';

import 'package:barzzy_app1/BarPages/OrderDisplay.dart';
import 'package:barzzy_app1/Extra/bottombar.dart';
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



  //SIGN USER IN

  void signUserIn() async {
  final cacher = LoginCache();
  final url = Uri.parse('https://www.barzzy.site/signup/login');
  final requestBody = jsonEncode({
    'email': emailController.value.text,
    'password': passwordController.value.text
  });
  
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json', // Specify that the body is JSON
    },
    body: requestBody,
  );

  if (response.statusCode == 200) {
    print('login Request successful');
    print('login Response body: ${response.body}');

    try {
      // Added this: Parse the response body as an integer
      int responseValue = int.parse(response.body);

      // Added this: Proper integer comparison
      if (responseValue > 0) {
        cacher.setEmail(emailController.value.text);
        cacher.setPW(passwordController.value.text);
        cacher.setSignedIn(true);
        cacher.setUID(responseValue);

        debugPrint("UserLogin");
        // Navigate to AuthPage if responseValue is greater than 0
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const AuthPage())
        );
      } else {
        debugPrint("BarLogin");

        cacher.setEmail(emailController.value.text);
        cacher.setPW(passwordController.value.text);
        cacher.setSignedIn(true);
        cacher.setUID(responseValue);

        // Navigate to OrderDisplay if responseValue is 0 or negative
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const OrderDisplay())
        );
      }
    } catch (e) {
      // Handle any parsing or other errors
      debugPrint('Error: $e');
      failure();
    }
  } else {
    print('login Request failed with status: ${response.statusCode}');
    print('login Response body: ${response.body}');
    invalidCredentialsMessage();
  }
}



    void failure() {
    showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
            backgroundColor: Colors.white,
          title: Center(child: 
          Text('Oopsies. Looks like something went wrong. Please try again.', 
          style:TextStyle(color: Color.fromARGB(255, 30, 30, 30),
          fontWeight: FontWeight.bold,) )));
        });
  }

  //INVALID CREDENTIALS POP UP

  void invalidCredentialsMessage() {
    showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
            backgroundColor: Colors.white,
          title: Center(child: 
          Text('Looks like you may have typed in the wrong email or password. Please try again!', 
          style:TextStyle(color: Color.fromARGB(255, 30, 30, 30),
          fontWeight: FontWeight.bold,) )));
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
                'B A R Z Z Y',
                style: GoogleFonts.megrim(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 35,
                ),
              ),
            ),

          const SizedBox(height: 125),

            

            // USER/EMAIL TEXTFIELD

            MyTextField(
              labeltext: 'Email',
              controller: emailController,
              obscureText: false,
            ),
            const SizedBox(height: 10),

            // PASSWORD TEXTFIELD

            MyTextField(
                labeltext: 'Password',
                controller: passwordController,
                obscureText: true),
            const SizedBox(height: 10),

            // FORGOT PASSWORD

            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text("Forgot Password?",
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.bold
                      )),
                  SizedBox(height: 25),
                ])),
            const SizedBox(height: 25),

            // SIGN IN

            MyButton(text: 'Sign In', onTap: signUserIn,), const SizedBox(height: 25),
            
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
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ])
          ]),
        ))));
  }
}