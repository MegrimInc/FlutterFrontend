import 'package:barzzy_app1/AuthPages/RegisterPages/register2.dart';
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


  final validCharacters = RegExp(r'^[a-zA-Z]+$');

  final firstName = TextEditingController();

  final lastName = TextEditingController();

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
            backgroundColor: Color.fromARGB(255, 255, 190, 68),
          title: Center(child: 
          Text('Invalid name. Please check your fields.', 
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




            MyButton(text: 'Next Step', onTap: registerNames,), const SizedBox(height: 25),
            
            const SizedBox(height: 30),
            const SizedBox(height: 50),

          ]),
        ))));
  }
}