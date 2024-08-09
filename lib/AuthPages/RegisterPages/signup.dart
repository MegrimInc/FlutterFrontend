import 'dart:convert';
import 'package:barzzy_app1/AuthPages/RegisterPages/verification.dart';
import 'package:http/http.dart' as http;

import 'package:barzzy_app1/AuthPages/RegisterPages/logincache.dart';

import 'package:barzzy_app1/AuthPages/components/mybutton.dart';
import 'package:barzzy_app1/AuthPages/components/mytextfield.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';




class RegisterPage extends StatefulWidget {
  final Function()? onTap;

  const RegisterPage({super.key, this.onTap});  

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {


  final validCharacters = RegExp(r'^[a-zA-Z]+$');

  final firstName = TextEditingController();

  final lastName = TextEditingController();


  final email = TextEditingController();

    final password = TextEditingController();

  //SIGN USER IN

  void registerNames() async {


    if( firstName.value.text.isNotEmpty && lastName.value.text.isNotEmpty 
    && firstName.value.text.length < 25 && lastName.value.text.length < 25 
    && validCharacters.hasMatch(firstName.value.text + lastName.value.text) ) {

      final loginCache2 = LoginCache();
      loginCache2.setEmail(email.value.text);
      loginCache2.setFN(firstName.value.text);
      loginCache2.setPW(password.value.text);
      loginCache2.setLN(lastName.value.text);
      loginCache2.setSignedIn(true);

final url = Uri.parse('https://www.barzzy.site/signup/register');
  // Create the request body
  final requestBody = jsonEncode({
    'email': email.value.text,
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
    if(response.body == "sent email") {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage11(message: "Sent verification email.")));
    } else if(response.body == "Re-sent email") {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage11(message: "Re-sent verification email.")));
    } else {
      invalidEmail();
    }
  } else {
    print('01Request failed with status: ${response.statusCode}');
    print('01Response body: ${response.body}');
    failure();

  }      

    } else {
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
          Text('Something went wrong. Please try again later.', 
          style:TextStyle(color: Color.fromARGB(255, 30, 30, 30),
          fontWeight: FontWeight.bold,) )));
        });
  }

    void invalidEmail() {
    showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
            backgroundColor: Colors.white,
          title: Center(child: 
          Text('Invalid email. Please try again.', 
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
          Text('Invalid input. Please check your fields.', 
          style:TextStyle(color: Color.fromARGB(255, 30, 30, 30),
          fontWeight: FontWeight.bold,) )));
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

            

            // USER/EMAIL TEXTFIELD

            MyTextField(
              labeltext: 'Enter First Name',
              controller: firstName,
              obscureText: false,
            ),
            const SizedBox(height: 10),

            // PASSWORD TEXTFIELD

            MyTextField(
                labeltext: 'Enter Last Name',
                controller: lastName,
                obscureText: false),
            const SizedBox(height: 10),


            MyTextField(
                labeltext: 'Enter Email Address',
                controller: email,
                obscureText: false),
            const SizedBox(height: 10),

            MyTextField(
                labeltext: 'Create Password',
                controller: password,
                obscureText: true),
            const SizedBox(height: 10),



            MyButton(text: 'Signup', onTap: registerNames,), const SizedBox(height: 25),
            
           
            const SizedBox(height: 45),

          

            // NOT A MEMBER REGISTER NOW

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Already have an account?',
                  style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: widget.onTap,
                child: const Text('Login',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ])

          ]),
        ))));
  }
}