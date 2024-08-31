
import 'package:flutter/material.dart';

class TabsPage extends StatefulWidget {
  

  const TabsPage({super.key,});

  @override
  State<TabsPage> createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage> {
  




@override
  void initState() {
    super.initState();
    
     // Clear histories when this page is navigated to
    WidgetsBinding.instance.addPostFrameCallback((_) {

    });
  }

  
  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: Colors.black, 
    );
  }
}