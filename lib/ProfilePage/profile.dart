import 'package:barzzy_app1/ProfilePage/profiletopicons.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black, 
      body: Column(
      
      
      
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        
         //TOP ICON BAR
         
         MyTopIcons1()
         ]
          
         ),
      );
  }
}