import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double imageHeight = size.height * 0.4;  // Height of the image container
    final double imageWidth = size.width * 0.9;   // Width of the image container

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Expanded content container
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            bottom: isExpanded ? size.height * 0.2 : imageHeight - 1, // Slightly below the image when not expanded
            left: isExpanded ? size.width * 0.03 : size.width * 0.45 - 0.5, // Minimized and centered behind image
            right: isExpanded ? size.width * 0.03 : size.width * 0.45 - 0.5,
            height: isExpanded ? imageHeight * 1.1 : 1,  // Tiny height when not expanded
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: isExpanded ? Radius.circular(20) : Radius.zero,
                  bottomRight: isExpanded ? Radius.circular(20) : Radius.zero,
                ),
              ),
            ),
          ),
          // Image container
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            bottom: isExpanded ? size.height * 0.3 : size.height * 0.25,  // Moves up slightly when expanded
            child: GestureDetector(
              onVerticalDragUpdate: _handleDragUpdate,
              child: Container(
                width: imageWidth,
                height: imageHeight,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage("lib/components/images/background.jpeg"),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (details.primaryDelta! < 0 && !isExpanded) { // Use && for logical AND
      setState(() => isExpanded = true);
    } else if (details.primaryDelta! > 0 && isExpanded) { // Corrected logical condition
      setState(() => isExpanded = false);
    }
}

}
