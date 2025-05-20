// ignore_for_file: use_build_context_synchronously, unused_element

import 'dart:convert';
import 'package:barzzy/UI/AuthPages/RegisterPages/tos.dart';
import 'package:barzzy/UI/AuthPages/RegisterPages/verification.dart';
import 'package:barzzy/UI/HomePage/home.dart';
import 'package:barzzy/config.dart';
import 'package:http/http.dart' as http;

import 'package:barzzy/UI/AuthPages/RegisterPages/logincache.dart';

import 'package:barzzy/UI/AuthPages/components/mybutton.dart';
import 'package:barzzy/UI/AuthPages/components/mytextfield.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;

  const RegisterPage({super.key, this.onTap});

  @override
  State<RegisterPage> createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final validCharacters = RegExp(r'^[a-zA-Z]+[a-zA-Z ]*$');
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool _showOverlay = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final FocusNode firstNameNode = FocusNode();
  final FocusNode lastNameNode = FocusNode();
  final FocusNode emailNode = FocusNode();
  final FocusNode passwordNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  void _showOverlayWidget() {
    FocusScope.of(context).unfocus();
    setState(() {
      _showOverlay = true;
    });
    _animationController.forward().then((_) {});
  }

  //SIGN USER IN

 void registerNames() async {
  FocusScope.of(context).unfocus();

  if (firstName.value.text.isNotEmpty &&
      lastName.value.text.isNotEmpty &&
      firstName.value.text.length < 25 &&
      lastName.value.text.length < 25 &&
      validCharacters.hasMatch(firstName.value.text + lastName.value.text)) {

    final url = Uri.parse('${AppConfig.postgresApiBaseUrl}/auth/register-customer');
    
    final requestBody = jsonEncode({
      'email': email.value.text.trim().toLowerCase(),
      'firstName': firstName.value.text.trim(),
      'lastName': lastName.value.text.trim(),
      'password': password.value.text,
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: requestBody,
    );

    if (response.statusCode == 200) {
      debugPrint('Account created successfully');
      debugPrint('Response body: ${response.body}');

      // Store the customer Id in the login cache
      final loginCache2 = LoginCache();
      loginCache2.setEmail(email.value.text.trim().toLowerCase());
      loginCache2.setFN(firstName.value.text.trim());
      loginCache2.setPW(password.value.text);
      loginCache2.setLN(lastName.value.text.trim());
      loginCache2.setSignedIn(true);

      // Store the customer Id returned from the backend
      final customerId = int.parse(response.body);
      loginCache2.setUID(customerId);

      // Navigate to the next page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RegisterPage2()),
      );
    } else if (response.statusCode == 409 &&
           response.body.trim().toLowerCase() == 'email already exists') {
  emailAlreadyExists();
} else {
  debugPrint('Request failed with status: ${response.statusCode}');
  debugPrint('Response body: ${response.body}');
  failure();
}
  } else {
    invalidCredentialsMessage();
  }
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
          child: Stack(
            children: [
              _buildMainContent(),

              // Overlay content
              if (_showOverlay)
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform(
                      transform: Matrix4.identity()
                        ..scale(_animation.value)
                        ..translate(
                          -1.0 *
                              MediaQuery.of(context).size.width /
                              2 *
                              (1 - _animation.value),
                          MediaQuery.of(context).size.height *
                              (1 - _animation.value),
                        ),
                      alignment: Alignment.bottomLeft,
                      child: FadeTransition(
                        opacity: _animation,
                        child: child,
                      ),
                    );
                  },
                  child: RegisterPage11(
                    hideOverlay: _hideOverlayWidget,
                    onResend: registerNames,
                  ),
                ),
            ],
          ),
        ));
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 21),
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

              const SizedBox(height: 45),
              MyTextField(
                labeltext: 'Enter First Name',
                controller: firstName,
                obscureText: false,
                focusNode: firstNameNode,
              ),
              const SizedBox(height: 10),
              MyTextField(
                labeltext: 'Enter Last Name',
                controller: lastName,
                obscureText: false,
                focusNode: lastNameNode,
              ),
              const SizedBox(height: 10),
              MyTextField(
                labeltext: 'Enter Email Address',
                controller: email,
                obscureText: false,
                focusNode: emailNode,
              ),
              const SizedBox(height: 10),
              MyTextField(
                labeltext: 'Create Password',
                controller: password,
                obscureText: true,
                focusNode: passwordNode,
              ),
              const SizedBox(height: 10),
              MyButton(
                text: 'Create Account',
                onTap: () {
                  // Close the keyboard
                  FocusScope.of(context).unfocus();

                  // Call the registerNames method
                  registerNames();
                },
              ),
              
              const SizedBox(height: 45),
               
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account?',
                    style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(top: 2.5),
                child: Text(
                  'or',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2.5),
                child: GestureDetector(
                  onTap: () {
                    // Navigate to HomePage when the button is tapped
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Login as Guest',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void failure() {
    showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
              backgroundColor: Colors.white,
              title: Center(
                  child: Text('Something went wrong. Please try again later.',
                      style: TextStyle(
                        color: Color.fromARGB(255, 30, 30, 30),
                        fontWeight: FontWeight.bold,
                      ))));
        });
  }

  void emailAlreadyExists() {
    showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
              backgroundColor: Colors.white,
              title: Center(
                  child: Text('Email already exists.',
                      style: TextStyle(
                        color: Color.fromARGB(255, 30, 30, 30),
                        fontWeight: FontWeight.bold,
                      ))));
        });
  }

  void invalidEmail() {
    showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
              backgroundColor: Colors.white,
              title: Center(
                  child: Text('Invalid email. Please try again.',
                      style: TextStyle(
                        color: Color.fromARGB(255, 30, 30, 30),
                        fontWeight: FontWeight.bold,
                      ))));
        });
  }

  //INVALId CREDENTIALS POP UP

  void invalidCredentialsMessage() {
    showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
              backgroundColor: Colors.white,
              title: Center(
                  child: Text('Invalid input. Please check your fields.',
                      style: TextStyle(
                        color: Color.fromARGB(255, 30, 30, 30),
                        fontWeight: FontWeight.bold,
                      ))));
        });
  }

  void _hideOverlayWidget() {
    FocusScope.of(context).unfocus();
    _animationController.reverse().then((_) {
      setState(() {
        _showOverlay = false;
      });
    });
  }

  @override
  void dispose() {
    // Dispose of FocusNodes and controllers
    firstNameNode.dispose();
    lastNameNode.dispose();
    emailNode.dispose();
    passwordNode.dispose();
    firstName.dispose();
    lastName.dispose();
    email.dispose();
    password.dispose();
    _animationController.dispose();
    super.dispose();
  }
}