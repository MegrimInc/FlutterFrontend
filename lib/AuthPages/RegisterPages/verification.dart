// ignore_for_file: use_build_context_synchronously

import 'dart:ui';
import 'package:barzzy_app1/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy_app1/AuthPages/RegisterPages/tos.dart';
import 'package:barzzy_app1/AuthPages/components/keypad.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class RegisterPage11 extends StatefulWidget {
  final String message;
  final void Function()? hideOverlay;
  final VoidCallback? onResend;

  const RegisterPage11({
    super.key,
    required this.message,
    this.hideOverlay,
    this.onResend,
  });

  @override
  State<RegisterPage11> createState() => _RegisterPageState11();
}

class _RegisterPageState11 extends State<RegisterPage11>
    with SingleTickerProviderStateMixin {
  final verificationCode = TextEditingController();
  final loginCache4 = LoginCache();
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  void attemptVerification() async {
    final url = Uri.parse('https://www.barzzy.site/signup/verify');
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
      debugPrint('Request successful');
      debugPrint('Response body: ${response.body}');
      int uid = int.parse(response.body);
      if (uid == 0) {
        incorrect();
      } else if (uid > 0) {
        final loginCache4 = LoginCache();
        loginCache4.setUID(uid);
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const RegisterPage2()));
      }
    } else {
      debugPrint('Request failed with status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      failure();
      setState(() {
          verificationCode.clear();
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(147, 0, 0, 0),
      body: GestureDetector(
        onTap: widget.hideOverlay,
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
              child: Container(
                color: Colors.transparent,
              ),
            ),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 75),
                    Text(
                      widget.message,
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    const SizedBox(height: 50),

                    // Display the IOS-style Keypad
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _animation.value,
                          child: FadeTransition(
                            opacity: _animation,
                            child: child,
                          ),
                        );
                      },
                      child: IOSStyleKeypad(
                        controller: verificationCode,
                        onCompleted: (code) {
                          attemptVerification();
                        },
                         onResend: widget.onResend,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                )),
          ),
        );
      },
    );
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
                )),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
