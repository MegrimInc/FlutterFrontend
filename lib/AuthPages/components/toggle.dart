import 'package:barzzy/AuthPages/RegisterPages/login.dart';
import 'package:barzzy/AuthPages/RegisterPages/signup.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginOrRegisterPage extends StatefulWidget {
  const LoginOrRegisterPage({super.key});

  @override
  State<LoginOrRegisterPage> createState() => _LoginOrRegistrationPageState();
}

class _LoginOrRegistrationPageState extends State<LoginOrRegisterPage> {
  bool isCodeVerified = false;
  bool showLoginPage = true;

  final TextEditingController codeController = TextEditingController();

  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  void verifyCode(String enteredCode) {
    const String correctCode = '197302'; // Replace with actual code logic
    if (enteredCode == correctCode) {
      setState(() {
        isCodeVerified = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
   const SnackBar(
    content: Center(
      child: Text(
        'Incorrect code. Please try again.',
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
    ),
    backgroundColor: Color.fromARGB(54, 188, 188, 188),
    //behavior: SnackBarBehavior.floating, // Optional: Makes the snackbar float
  ),
);
      codeController.clear(); // Clear the entered code when it's incorrect
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isCodeVerified) {
      return SafeArea(
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 75),
        
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
        
              const SizedBox(height: 50),
                
                IOSStyleKeypad(
                  controller: codeController,
                  onCompleted: verifyCode,
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      if (showLoginPage) {
        return RegisterPage(onTap: togglePages);
      } else {
        return LoginPage(onTap: togglePages);
      }
    }
  }
}

class IOSStyleKeypad extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onCompleted;
  

  const IOSStyleKeypad({
    super.key,
    required this.controller,
    this.onCompleted,
  });

  @override
  IOSStyleKeypadState createState() => IOSStyleKeypadState();
}

class IOSStyleKeypadState extends State<IOSStyleKeypad> {
  void _handleCompletion(String code) {
    if (widget.onCompleted != null) {
      widget.onCompleted!(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 45),
            child: Text(
              widget.controller.text,
              style: const TextStyle(fontSize: 40, color: Colors.white),
            ),
          ),
          _buildKeypad(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKey('1'),
            _buildKey('2'),
            _buildKey('3'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKey('4'),
            _buildKey('5'),
            _buildKey('6'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKey('7'),
            _buildKey('8'),
            _buildKey('9'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKey('0'),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // RESEND
            Container(
              width: 120,
              height: 60,
              color: Colors.transparent,
              child: const Center(
                child: Text(
                  'resend',
                  style: TextStyle(
                    color: Colors.black, fontSize: 20),
                ),
              ),
            ),
            // BACKSPACE
            _buildBackspaceKey()
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String value) {
    return GestureDetector(
      onTap: () {
        if (widget.controller.text.length < 6) {
          setState(() {
            widget.controller.text += value;
          });
          if (widget.controller.text.length == 6) {
            _handleCompletion(widget.controller.text);
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.all(8.0),
        width: 75,
        height: 75,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color.fromARGB(54, 188, 188, 188),
        ),
        alignment: Alignment.center,
        child: Text(
          value,
          style: const TextStyle(fontSize: 30, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey() {
    return GestureDetector(
      onTap: () {
        if (widget.controller.text.isNotEmpty) {
          setState(() {
            widget.controller.text = widget.controller.text
                .substring(0, widget.controller.text.length - 1);
          });
        } 
      },
      child: Container(
        width: 120,
        height: 60,
        color: const Color.fromRGBO(0, 0, 0, 0),
        child:  Center(
          child: Text(
             widget.controller.text.isNotEmpty ? 'delete' : '',
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 20),
          ),
        ),
      ),
    );
  }
}