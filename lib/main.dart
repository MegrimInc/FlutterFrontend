import 'dart:convert';

import 'package:barzzy_app1/Backend/bar.dart';
import 'package:barzzy_app1/Backend/searchengine.dart';
import 'package:barzzy_app1/Backend/recommended.dart';
import 'package:barzzy_app1/Backend/user.dart';
// import 'package:barzzy_app1/OrdersPage/cart.dart';
// import 'package:barzzy_app1/test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barzzy_app1/Backend/bardatabase.dart';
import 'package:http/http.dart' as http;
import 'package:barzzy_app1/Extra/auth.dart';
import 'package:barzzy_app1/Backend/barhistory.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  BarDatabase barDatabase = BarDatabase();
  
  await sendGetRequest();


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => barDatabase),
        ChangeNotifierProvider(create: (context) => BarHistory()),
        ChangeNotifierProvider(create: (context) => Recommended()),
        ChangeNotifierProvider(create: (context) => User()),
        
        ProxyProvider<BarDatabase, SearchService>(
          update: (_, barDatabase, __) => SearchService(barDatabase),)
      ],
      child: const Barzzy(),
    ),
  );
}




Future<void> sendGetRequest() async {
    try {
      final url = Uri.parse('https://www.barzzy.site/bars/seeAll');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        debugPrint('GET request successful');
        
        // Print the raw JSON response
        debugPrint('Response body: ${response.body}');
        
        // Decode and print formatted JSON
        final List<dynamic> jsonResponse = jsonDecode(response.body);
        //final jsonResponse = jsonDecode(response.body);
        debugPrint('Decoded JSON response: ${jsonResponse.toString()}');


        BarDatabase barDatabase = BarDatabase();
      for (var barJson in jsonResponse) {
        Bar bar = Bar.fromJson(barJson);
        barDatabase.addBar(bar);
      }

      debugPrint('All bars have been added to the database.');
      
        
      } else {
        debugPrint('Failed to send GET request');
        debugPrint('Response status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending GET request: $e');
    }
  }











class Barzzy extends StatelessWidget {
  const Barzzy({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      //home: Testing()
      home: const AuthPage(),
      
    );
  }
}