import 'dart:convert';
import 'package:barzzy/AuthPages/RegisterPages/verification.dart';
import 'package:http/http.dart' as http;

import 'package:barzzy/AuthPages/RegisterPages/logincache.dart';

import 'package:barzzy/AuthPages/components/mybutton.dart';
import 'package:barzzy/AuthPages/components/mytextfield.dart';
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
      final loginCache2 = LoginCache();
      loginCache2.setEmail(email.value.text.trim());
      loginCache2.setFN(firstName.value.text.trim());
      loginCache2.setPW(password.value.text);
      loginCache2.setLN(lastName.value.text.trim());
      loginCache2.setSignedIn(true);

      final url = Uri.parse('https://www.barzzy.site/signup/register');
      final requestBody = jsonEncode({
        'email': email.value.text.trim(),
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json', // Specify that the body is JSON
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        debugPrint('Request successful');
        debugPrint('Response body: ${response.body}');

        if (response.body == "sent email") {
          _showOverlayWidget();
        } else if (response.body == "Re-sent email") {
          _showOverlayWidget();
        } else {
          invalidEmail();
          return;
        }
      } else {
        debugPrint('01Request failed with status: ${response.statusCode}');
        debugPrint('01Response body: ${response.body}');
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
              const SizedBox(height: 50),
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
              const SizedBox(height: 100),
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
                text: 'Signup',
                onTap: () {
                  // Close the keyboard
                  FocusScope.of(context).unfocus();

                  // Call the registerNames method
                  registerNames();
                },
              ),
              const SizedBox(height: 25),
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

  //INVALID CREDENTIALS POP UP

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
