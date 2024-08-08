import 'package:barzzy_app1/AuthPages/components/mybutton.dart';
import 'package:barzzy_app1/HomePage/home.dart';
import 'package:flutter/material.dart';

class RegisterPage2 extends StatefulWidget {
  final void Function()? onTap;
  const RegisterPage2({super.key, this.onTap});  

  @override
  State<RegisterPage2> createState() => _RegisterPageState2();
}

class _RegisterPageState2 extends State<RegisterPage2> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barzzy Terms of Services'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [ 
                const SizedBox(height: 100),
                const Text('Terms Go Here!'),
                const SizedBox(height: 100),
                MyButton(text: 'I have read and agree to the Terms of Services', onTap: () {
                    
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
                   },),
        ]),


      ),
      
    );
  } 

}
