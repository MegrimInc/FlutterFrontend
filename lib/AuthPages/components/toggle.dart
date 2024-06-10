import 'package:barzzy_app1/AuthPages/LoginPage/login.dart';
import 'package:barzzy_app1/AuthPages/SignupPage/signup.dart';

import 'package:flutter/material.dart';



class LoginOrRegisterPage extends StatefulWidget {
  const LoginOrRegisterPage({super.key});

  @override
  State<LoginOrRegisterPage> createState() => _LoginOrRegistrationPageState();
}

class _LoginOrRegistrationPageState extends State<LoginOrRegisterPage> {
  //INITIALLY SHOW LOGIN PAGE
  bool showLoginPage = true;

  //TOGGLE
  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(
        onTap: togglePages,
      );
    } else {
      return RegisterPage(onTap: togglePages,);
    }
  }
}