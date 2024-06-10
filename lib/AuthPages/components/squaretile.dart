import 'package:flutter/material.dart';

class SquareTile extends StatelessWidget {
  final String imagePath;
  const SquareTile({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: const Color.fromARGB(255, 15, 15, 15),
            border: Border.all(
              color: const Color.fromARGB(255, 60, 60, 60),
            ),
            borderRadius: BorderRadius.circular(16)),
        child: Image.asset(imagePath, height: 40));
  }
}
