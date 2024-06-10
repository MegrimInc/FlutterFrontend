import 'package:flutter/material.dart';

class ActionSheet extends StatelessWidget {
  const ActionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showActionSheet(context);
      },
      child: Container(
        alignment: Alignment.center,
        color: Colors.grey,
        width: double.infinity,
        height: 50, // Adjust the height according to your needs
        child: const Text(
          'Show Action Sheet',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Option 1'),
                onTap: () {
                  Navigator.pop(context);
                  // Perform action for Option 1
                },
              ),
              ListTile(
                title: const Text('Option 2'),
                onTap: () {
                  Navigator.pop(context);
                  // Perform action for Option 2
                },
              ),
              ListTile(
                title: const Text('Cancel', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.black,
      body: ActionSheet(),
    ),
  ));
}
