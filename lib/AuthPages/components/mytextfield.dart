import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labeltext;
  final bool obscureText;
  final Color labelColor;
  final FocusNode focusNode;  // Add this parameter

  const MyTextField({
    super.key,
    required this.controller,
    required this.obscureText,
    required this.labeltext,
    required this.focusNode,  // Add this to the constructor
    this.labelColor = const Color.fromARGB(255, 255, 255, 255),
  });

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<bool> isFocused = ValueNotifier<bool>(false);

    focusNode.addListener(() {
      isFocused.value = focusNode.hasFocus;
    });

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 25,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildLabelText(isFocused),
          const SizedBox(height: 2),
          ValueListenableBuilder<bool>(
            valueListenable: isFocused,
            builder: (context, focused, child) {
              return TextField(
                controller: controller,
                obscureText: !focused && obscureText,
                style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                cursorColor: Colors.white,
                focusNode: focusNode,  // Use the passed focus node
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(
                        color: Color.fromARGB(255, 60, 60, 60)
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(
                        color: Colors.white),
                  ),
                  fillColor: focused
                      ? Colors.black
                      : const Color.fromARGB(255, 60, 60, 60),
                  filled: true,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildLabelText(ValueNotifier<bool> isFocused) {
    return Text(
      labeltext,
      style: labelTextStyle(isFocused),
    );
  }

  TextStyle labelTextStyle(ValueNotifier<bool> isFocused) {
    return TextStyle(
      color: isFocused.value
          ? const Color.fromARGB(255, 150, 66, 224)
          : labelColor,
      fontWeight: FontWeight.bold, // Make the label text bold
    );
  }
}