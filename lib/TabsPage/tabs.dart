import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // Import Crashlytics

class TabsPage extends StatefulWidget {
  const TabsPage({super.key});

  @override
  State<TabsPage> createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage> {
  @override
  void initState() {
    super.initState();

    // Clear histories when this page is navigated to
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Your code here
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
       backgroundColor: Colors.black,
      // // Add a button to trigger the crash
      // body: Center(
      //   child: ElevatedButton(
      //     onPressed: () {
      //       // Trigger a crash when the button is pressed
      //       FirebaseCrashlytics.instance.crash();
      //     },
      //     child: const Text('Crash the App'),
      //   ),
      // ),
    );
  }
}