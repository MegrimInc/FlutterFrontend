import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyListTile extends StatelessWidget {
  final IconData icon;
  final String text; 
  final void Function()? onTap;
  final Color iconColor;
  final Color textColor;

  const MyListTile({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.iconColor = Colors.grey, // Default color for the icon
    this.textColor = Colors.grey, // Default color for the text
  });

  @override
  Widget build(BuildContext context) {
    return Padding( 
      padding: const EdgeInsets.only(top: 25),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor, // Use the provided icon color
        ), 
        onTap: onTap,
        title: Padding(
          padding: const EdgeInsets.only(left: 25),
          child: Text(
            text,
            style: GoogleFonts.sourceSans3( // Apply Google Fonts to the text style
              textStyle: TextStyle(
                color: textColor, // Use the provided text color
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}