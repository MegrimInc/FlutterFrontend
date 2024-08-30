import 'dart:convert';

import 'package:barzzy_app1/AuthPages/RegisterPages/logincache.dart';

import 'package:barzzy_app1/AuthPages/components/toggle.dart';
import 'package:barzzy_app1/Backend/bar.dart';
import 'package:barzzy_app1/Backend/drink.dart';
import 'package:barzzy_app1/Backend/searchengine.dart';
import 'package:barzzy_app1/Backend/recommended.dart';
import 'package:barzzy_app1/backend/tags.dart';
import 'package:barzzy_app1/Backend/user.dart';
import 'package:barzzy_app1/Gnav%20Bar/bottombar.dart';
import 'package:barzzy_app1/OrdersPage/hierarchy.dart';
import 'package:barzzy_app1/Terminal/ordersv2-0.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barzzy_app1/Backend/localdatabase.dart';
import 'package:http/http.dart' as http;
import 'package:barzzy_app1/Backend/barhistory.dart';

void main() async {
  debugPrint("current date: ${DateTime.now()}");

  WidgetsFlutterBinding.ensureInitialized();
  final loginCache = LoginCache();
  // await loginCache.clearAll();

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

  LocalDatabase localDatabase = LocalDatabase();
  User user = User();
  await sendGetRequest();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => localDatabase),
        ChangeNotifierProvider(create: (context) => BarHistory()),
        ChangeNotifierProvider(create: (context) => Recommended()),
        ChangeNotifierProvider(create: (context) => Hierarchy(context)),
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
        await fetchTagsAndDrinks(bar.id!);
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

Future<void> fetchTagsAndDrinks(String barId) async {
  LocalDatabase barDatabase = LocalDatabase();
  User user = User();

  // Define hardcoded static tag IDs and their corresponding names
  List<MapEntry<int, String>> tagList = [
    const MapEntry(171, 'vodka'),
    const MapEntry(172, 'gin'),
    const MapEntry(173, 'whiskey'),
    const MapEntry(174, 'tequila'),
    const MapEntry(175, 'brandy'),
    const MapEntry(176, 'rum'),
    const MapEntry(177, 'ale'),
    const MapEntry(178, 'lager'),
    const MapEntry(180, 'juice'),
    const MapEntry(181, 'soda'),
    const MapEntry(182, 'red wine'),
    const MapEntry(183, 'white wine'),
    const MapEntry(185, 'seltzer'),
  ];

  debugPrint('Starting to fetch tags and drinks for barId: $barId');
  
  for (var entry in tagList) {
    int tagId = entry.key;
    String tagName = entry.value;

    debugPrint('Processing tag: $tagName ($tagId)');
    
    // Create and add Tag objects to the internal tag map
    Tag tag = Tag(id: tagId.toString(), name: tagName);
    barDatabase.addTag(tag);
    debugPrint('Added tag to database: ${tag.name}');

    // Fetch drinks for this tag
    final url = Uri.parse(
        'https://www.barzzy.site/bars/getRandomDrinks?barId=$barId&categoryId=$tagId');
    final response = await http.get(url);

    debugPrint('Requesting drinks for tag: $tagName ($tagId) from URL: $url');
    
    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      List<String> drinkIds = [];

      debugPrint('Response received for tag $tagName: $jsonResponse');

      for (var drinkJson in jsonResponse) {
        String? drinkId = drinkJson['drinkId']?.toString();
        if (drinkId != null) {
          Drink drink = Drink.fromJson(drinkJson);
          barDatabase.addDrink(drink);
          drinkIds.add(drinkId);
          debugPrint('Added drink to database: ${drink.name} (ID: $drinkId)');
        } else {
          debugPrint('Warning: Drink ID is null for drink: $drinkJson');
        }
      }

      user.addQueryToHistory(barId, tagName);
      user.addSearchQuery(barId, tagName, drinkIds);

      debugPrint(
          'Drinks for tag $tagName ($tagId) have been added to the database for bar $barId with drink IDs: $drinkIds');
    } else {
      debugPrint('Failed to load drinks for tag $tagId. Status code: ${response.statusCode}');
    }
  }

  debugPrint('Finished processing tags and drinks for barId: $barId');
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
      //home: OrdersPage(bartenderID: "test"),
      //ALREADY COMMENTED home: loggedInAlready ? (isBar ? const OrderDisplay() : const AuthPage()) : const LoginOrRegisterPage()//Make it so that when bars sign in, they get sent to
      initialRoute: initialRoute, // Set the initial route based on the logic

      routes: {
        '/auth': (context) =>
            const AuthPage(), // Your main app page for non-bar users
        '/bar': (context) =>
            const BartenderIDScreen(), // Orders page for bar users
        '/login': (context) =>
            const LoginOrRegisterPage(), // Login or Register page
        '/orders': (context) => const AuthPage(selectedTab: 1),
        // Add other routes here if needed
      },
    );
  }
}
