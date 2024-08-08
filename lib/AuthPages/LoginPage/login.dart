// ignore_for_file: use_build_context_synchronously


import 'package:barzzy_app1/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy_app1/AuthPages/RegisterPages/register1.dart';
import 'package:barzzy_app1/AuthPages/components/mybutton.dart';
import 'package:barzzy_app1/AuthPages/components/mytextfield.dart';
import 'package:barzzy_app1/AuthPages/components/squaretile.dart';
import 'package:barzzy_app1/HomePage/home.dart';
import 'package:flutter/material.dart';


class LoginPage extends StatefulWidget {
  
  final Function()? onTap;
  LoginPage({super.key, required this.onTap});  

  //final loginCache2 = LoginCache();


  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // TEXT EDITING CONTROLLERS


  

  final emailController = TextEditingController();

  final passwordController = TextEditingController();


  void goRegister() async {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
  }


  //SIGN USER IN

  void signUserIn() async {

    //SHOW LOADING CIRCLE

    /*showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 255, 255, 255)));
        });*/

    //Send HTTP Request to server
    bool signIn = true;

    //signIn = http.parse(uri)

    if(/* Get HTTP request back*/ signIn == true) {
    //loginCache2.setSignedIn(true);
    //loginCache2.setEmail(email);
    //loginCache2.setPassword(password);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
    

    } else {
      invalidCredentialsMessage();
    }
    

    
  }

  //INVALID CREDENTIALS POP UP

  void invalidCredentialsMessage() {
    showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
            backgroundColor: Color.fromARGB(255, 255, 190, 68),
          title: Center(child: 
          Text('Looks like you may have typed in the wrong email or password. Please try again!', 
          style:TextStyle(color: Color.fromARGB(255, 30, 30, 30),
          fontWeight: FontWeight.bold,) )));
        });
  }

  @override
  Widget build(BuildContext context) {
    final loginCache2 = LoginCache();
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
            const SizedBox(height: 75),

            // ICONS: NEEDS TO BE CHANGED TO BARZZY LOGO
            const Icon(Icons.abc_outlined,
                size: 100, color: Color.fromARGB(255, 15, 15, 15)),
            const SizedBox(height: 100),

            

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

            // GOOGLE + APPLE + GMAIL SIGN IN

            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              // google button
              SquareTile(imagePath: 'lib/components/images/google.png'),
              SizedBox(width: 10),

              // apple button
              SquareTile(imagePath: 'lib/components/images/apple.png'),
              SizedBox(width: 10),
            ]),
            const SizedBox(height: 50),

            // NOT A MEMBER REGISTER NOW

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Not a member?',
                  style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: goRegister,
                child: const Text('Register Now',
                    style: TextStyle(
                        color: Color.fromARGB(255, 255, 172, 19),
                        fontWeight: FontWeight.bold)),
              ),
            ])
          ]),
        ))));
  }
}