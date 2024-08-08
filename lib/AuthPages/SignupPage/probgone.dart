// ignore_for_file: use_build_context_synchronously


import 'package:barzzy_app1/AuthPages/components/mybutton.dart';
import 'package:barzzy_app1/AuthPages/components/mytextfield.dart';
import 'package:flutter/material.dart';


class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // TEXT EDITING CONTROLLERS

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmpasswordController = TextEditingController();

  //SIGN USER IN

  void signUserUp() async {
    //SHOW LOADING CIRCLE

    showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 255, 255, 255)));
        });

  }

  //INVALID EMAIL POP UP

void invalidEmailorPassword() {
    showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(backgroundColor:  Color.fromARGB(255, 246, 190, 88), title: Center(child: 
          Text('You may be trying to sign in with an Invalid Email. Also check to make sure your passwords Match!', 
          style:TextStyle(color: Color.fromARGB(255, 30, 30, 30)))));
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
        backgroundColor: const Color.fromARGB(255, 15, 15, 15),
        body: SafeArea(
            child: Center(
                child: SingleChildScrollView(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 50),

            // ICONS: NEEDS TO BE CHANGED TO BARZZY LOGO
            const Icon(Icons.abc_outlined,
                size: 100, color: Color.fromARGB(255, 255, 15, 15, )),
            const SizedBox(height: 50),


            // USER/EMAIL TEXTFIELD

            MyTextField(
              labeltext: 'Email / Phone number',
              controller: emailController,
              obscureText: false,
            ),
            const SizedBox(height: 9),

            // PASSWORD TEXTFIELD

            MyTextField(
                labeltext: 'Password',
                controller: passwordController,
                obscureText: true),
            const SizedBox(height: 10),

            // CREATE PASSWORD TEXTFIELD

            MyTextField(
                labeltext: 'Confirm Password',
                controller: confirmpasswordController,
                obscureText: true),
            const SizedBox(height: 25),

            // SIGN UP

            MyButton(text: 'Sign Up', onTap: signUserUp),
            const SizedBox(height: 30),

            // OR CONTINUE WITH

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.0),
              child: Row(children: [
                Expanded(
                    child: Divider(
                        thickness: 0.5,
                        color: Color.fromARGB(255, 15, 15, 15))),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('or continue with',
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                      )),
                ),
                Expanded(
                    child: Divider(
                        thickness: 0.5, color: Color.fromARGB(255, 15, 15, 15)))
              ]),
            ),
            const SizedBox(height: 30),


            const SizedBox(height: 45),

            // NOT A MEMBER REGISTER NOW

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Already have an account?',
                  style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: widget.onTap,
                child: const Text('Login Now',
                    style: TextStyle(
                        color: Color.fromARGB(255, 255, 172, 19),
                        fontWeight: FontWeight.bold)),
              ),
            ])
          ]),
        ))));
  }
}