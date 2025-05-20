import 'package:barzzy/UI/AuthPages/RegisterPages/login.dart';
import 'package:barzzy/UI/AuthPages/RegisterPages/signup.dart';
import 'package:flutter/material.dart';



class LoginOrRegisterPage extends StatefulWidget {
  const LoginOrRegisterPage({super.key});

  @override
  State<LoginOrRegisterPage> createState() => _LoginOrRegistrationPageState();
}

class _LoginOrRegistrationPageState extends State<LoginOrRegisterPage> {
  //INITIALLY SHOW LOGIN PAGE
  bool showLoginPage = true;
  bool isCodeVerified = false;

  //TOGGLE
  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return RegisterPage(
        onTap: togglePages,
      );
    } else {
      return LoginPage(onTap: togglePages,);
    }
  }
}