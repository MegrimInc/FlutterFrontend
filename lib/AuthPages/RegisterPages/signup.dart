import 'package:barzzy_app1/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy_app1/AuthPages/RegisterPages/tos.dart';
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


    showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 255, 255, 255)));
        });

    if( firstName.value.text.isNotEmpty && lastName.value.text.isNotEmpty 
    && firstName.value.text.length < 25 && lastName.value.text.length < 25 
    && validCharacters.hasMatch(firstName.value.text + lastName.value.text) ) {

//Store FN/LN in memory and then do the SQL entry later
      final loginCache2 = LoginCache();
      loginCache2.setEmail(email.value.text);
      loginCache2.setFN(firstName.value.text);
      loginCache2.setPW(password.value.text);
      loginCache2.setLN(lastName.value.text);
      loginCache2.setSignedIn(true);
      Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage2()));
      

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
            backgroundColor: Colors.grey,
          title: Center(child: 
          Text('Invalid. Please check your fields.', 
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
                obscureText: true),
            const SizedBox(height: 10),


            MyTextField(
                labeltext: 'Enter Email Address',
                controller: email,
                obscureText: true),
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