import 'package:flutter/material.dart';

class Popup extends StatelessWidget {
  const Popup({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        const Text('Open/Close'),

         Container(
          decoration: 
          const BoxDecoration(),
          child: 
         const Text('Wait: 5 min')
         ),
         

         const Text('Pin')
        ],
      ),
    );
  }
}
