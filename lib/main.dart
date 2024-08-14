import 'dart:convert';

import 'package:barzzy_app1/AuthPages/RegisterPages/logincache.dart';

import 'package:barzzy_app1/AuthPages/components/toggle.dart';
import 'package:barzzy_app1/Backend/bar.dart';
import 'package:barzzy_app1/Backend/drink.dart';
import 'package:barzzy_app1/Backend/searchengine.dart';
import 'package:barzzy_app1/Backend/recommended.dart';
import 'package:barzzy_app1/Backend/tags.dart';
import 'package:barzzy_app1/Backend/user.dart';
import 'package:barzzy_app1/BarPages/orderdisplay.dart';
import 'package:barzzy_app1/Gnav%20Bar/bottombar.dart';
import 'package:barzzy_app1/OrdersPage/hierarchy.dart';
import 'package:barzzy_app1/Terminal/ordersv2-0.dart';
import 'package:barzzy_app1/Terminal/ordersv2-1.dart';
import 'package:barzzy_app1/QrPage/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barzzy_app1/Backend/localdatabase.dart';
import 'package:http/http.dart' as http;
import 'package:barzzy_app1/Backend/barhistory.dart';
import 'package:barzzy_app1/Backend/cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  debugPrint("current date: ${DateTime.now()}");

  WidgetsFlutterBinding.ensureInitialized();
  final loginCache = LoginCache();
  // await loginCache.clearAll();

  await printStoredOrders();

  bool loggedInAlready = true;
  await loginCache.getSignedIn() /* && HTTP REQUEST*/;
  final url = Uri.parse('https://www.barzzy.site/signup/login');
  final initPW = await loginCache.getPW();
  final initEmail = await loginCache.getEmail();

  // Create the request body
  final requestBody = jsonEncode({'email': initEmail, 'password': initPW});
  bool httprequest = false;
  // Send the POST request
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json', // Specify that the body is JSON
    },
    body: requestBody,
  );
  // Check the response
  if (response.statusCode == 200) {
    debugPrint('Init Request successful');
   debugPrint('Init Response body: ${response.body}');
    if (int.parse(response.body) != 0) httprequest = true;
  } else {
    debugPrint('Init Request failed with status: ${response.statusCode}');
    debugPrint('Init Response body: ${response.body}');
  }

  final uid = await loginCache.getUID();
  final isBar = uid < 0;
  debugPrint("User ID: $uid, isBar: $isBar");

  loggedInAlready = loggedInAlready && httprequest;
  debugPrint("Final loggedInAlready after request: $loggedInAlready");

  LocalDatabase barDatabase = LocalDatabase();
  await sendGetRequest();
  await fetchTags();
  await updateDrinkDatabase(barDatabase);
  final user = User();
  await user.init(); // Ensure User is fully initialized

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => barDatabase),
        ChangeNotifierProvider(create: (context) => BarHistory()),
        ChangeNotifierProvider(create: (context) => Recommended()),
        ChangeNotifierProvider(create: (context) => Hierarchy()),
        ChangeNotifierProvider(create: (_) => LoginCache()),
        ChangeNotifierProvider(create: (context) => user),
        ProxyProvider<LocalDatabase, SearchService>(
          update: (_, localDatabase, __) => SearchService(localDatabase),
        ),
      ],
      child: Barzzy(loggedInAlready: loggedInAlready, isBar: isBar),
    ),
  );
}

// Method to print orders stored in SharedPreferences
Future<void> printStoredOrders() async {
  final prefs = await SharedPreferences.getInstance();
  final orders = prefs.getString('orders') ?? '{}';
  debugPrint('Orders stored in SharedPreferences: $orders');
}

Future<void> sendGetRequest() async {
  try {
    final url = Uri.parse('https://www.barzzy.site/bars/seeAllBars');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      debugPrint('GET request successful');

      // Print the raw JSON response
      //debugPrint('Response body: ${response.body}');

      // Decode and print formatted JSON
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      //final jsonResponse = jsonDecode(response.body);
      debugPrint('Decoded JSON response: ${jsonResponse.toString()}');

      LocalDatabase barDatabase = LocalDatabase();
      for (var barJson in jsonResponse) {
        Bar bar = Bar.fromJson(barJson);
        // debugPrint('Parsed Bar Name: ${bar.name}');
        // debugPrint('Parsed Bar Image: ${bar.barimg}');
        // debugPrint('Parsed Tag Image: ${bar.tagimg}');
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

Future<void> fetchTags() async {
  try {
    final url = Uri.parse('https://www.barzzy.site/bars/seeAllTags');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      debugPrint('GET request for tags successful');

      // Decode and print formatted JSON
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      //debugPrint('Decoded JSON tags response: ${jsonResponse.toString()}');

      // Get the singleton instance of BarDatabase
     LocalDatabase barDatabase = LocalDatabase();

      // Process each tag from the JSON response
      for (var tagJson in jsonResponse) {
        Tag tag = Tag.fromJson(tagJson as Map<String, dynamic>);
        barDatabase.addTag(tag); // Add tag to the database
      }

      debugPrint('All tags have been added to the database.');
    } else {
      debugPrint('Failed to send GET request for tags');
      debugPrint('Response status code: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error sending GET request for tags: $e');
  }
}

Future<void> updateDrinkDatabase(LocalDatabase barDatabase) async {
  final cache = Cache();
  final cachedDrinkIds = await cache.getDrinkIds();

  for (String drinkId in cachedDrinkIds) {
    try {
      final drink = await fetchDrinkDetails(drinkId);
      barDatabase.addDrink(drink);
      //debugPrint('Added drink with ID $drinkId to the database');
    } catch (e) {
      debugPrint('Error fetching drink details for ID $drinkId: $e');
    }
  }
}

// Fetch drink details from backend
Future<Drink> fetchDrinkDetails(String drinkId) async {
  final url = Uri.parse('https://www.barzzy.site/bars/getOneDrink?id=$drinkId');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final jsonResponse = jsonDecode(response.body);
    debugPrint('Decoded JSON response: ${jsonResponse.toString()}');
    return Drink.fromJson(jsonResponse);
  } else {
    throw Exception('Failed to load drink details');
  }
}

class Barzzy extends StatelessWidget {
  final bool loggedInAlready;
  final bool isBar;
  const Barzzy({super.key, required this.loggedInAlready, required this.isBar});

  @override
  Widget build(BuildContext context) {
    Provider.of<BarHistory>(context, listen: false).setContext(context);
    Provider.of<Recommended>(context, listen: false)
        .fetchRecommendedBars(context);

    cameraControllerSingleton.initialize();

    // Decide the initial route
    final String initialRoute;
    if (!loggedInAlready) {
      initialRoute = '/login';
    } else if (isBar) {
      initialRoute = '/bar';
    } else {
      initialRoute = '/auth';
    }

    return MaterialApp(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: OrdersPage(bartenderID: "test"),
      //ALREADY COMMENTED home: loggedInAlready ? (isBar ? const OrderDisplay() : const AuthPage()) : const LoginOrRegisterPage()//Make it so that when bars sign in, they get sent to
      //initialRoute: initialRoute, // Set the initial route based on the logic
      
      routes: {
        '/auth': (context) =>
            const AuthPage(), // Your main app page for non-bar users
        '/bar': (context) => const OrderDisplay(), // Orders page for bar users
        '/login': (context) =>
            const LoginOrRegisterPage(), // Login or Register page
        '/orders': (context) => const AuthPage(selectedTab: 1),
        // Add other routes here if needed
      },
    );
  }
}
