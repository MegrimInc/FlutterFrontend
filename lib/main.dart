import 'dart:convert';

import 'package:barzzy_app1/AuthPages/RegisterPages/logincache.dart';

import 'package:barzzy_app1/AuthPages/components/toggle.dart';
import 'package:barzzy_app1/Backend/bar.dart';
import 'package:barzzy_app1/Backend/drink.dart';
import 'package:barzzy_app1/Backend/searchengine.dart';
import 'package:barzzy_app1/Backend/recommended.dart';
import 'package:barzzy_app1/backend/categories.dart';
import 'package:barzzy_app1/Backend/user.dart';
import 'package:barzzy_app1/Gnav%20Bar/bottombar.dart';
import 'package:barzzy_app1/OrdersPage/hierarchy.dart';
import 'package:barzzy_app1/Terminal/stationid.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barzzy_app1/Backend/localdatabase.dart';
import 'package:http/http.dart' as http;
import 'package:barzzy_app1/Backend/barhistory.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();


Future<void> showNotification() async {
const AndroidNotificationDetails androidNotificationDetails =
AndroidNotificationDetails(
'your_channel_id', // channel ID
'your_channel_name', // channel name
channelDescription: 'your_channel_description', // channel description
importance: Importance.max,
priority: Priority.high,
ticker: 'ticker',
);

const DarwinNotificationDetails darwinNotificationDetails =
DarwinNotificationDetails();

const NotificationDetails platformChannelSpecifics = NotificationDetails(
android: androidNotificationDetails,
iOS: darwinNotificationDetails,
);

await flutterLocalNotificationsPlugin.show(
0, // Notification ID
'Hello!', // Notification title
'Welcome to Barzzy!', // Notification body
platformChannelSpecifics, // Notification details specific to each platform
payload: 'app_started', // Payload to pass when the notification is tapped
);
}


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

await showNotification();



  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => localDatabase),
        ChangeNotifierProvider(create: (context) => BarHistory()),
        ChangeNotifierProvider(create: (context) => Recommended()),
        ChangeNotifierProvider(create: (context) => Hierarchy(context, navigatorKey)),
        ChangeNotifierProvider(create: (_) => LoginCache()),
        ChangeNotifierProvider(create: (context) => user),
        ProxyProvider<LocalDatabase, SearchService>(
          update: (_, localDatabase, __) => SearchService(localDatabase),
        ),
      ],
      child: Barzzy(
        loggedInAlready: loggedInAlready, 
        isBar: isBar,
        navigatorKey: navigatorKey, 
        ),
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

  // Corrected tagList with updated tag IDs
  // ignore: unused_local_variable
  List<MapEntry<int, String>> tagList = [
    const MapEntry(172, 'vodka'),
    const MapEntry(173, 'gin'),
    const MapEntry(174, 'whiskey'),
    const MapEntry(175, 'tequila'),
    const MapEntry(176, 'brandy'),
    const MapEntry(177, 'rum'),
    const MapEntry(178, 'ale'),
    const MapEntry(179, 'lager'),
    const MapEntry(181, 'virgin'),
    const MapEntry(183, 'red wine'),
    const MapEntry(184, 'white wine'),
    const MapEntry(186, 'seltzer'),
  ];

  // Initialize a Categories object with the correct tags
  Categories categories = Categories(
    barId: int.parse(barId),
    tag172: [],
    tag173: [],
    tag174: [],
    tag175: [],
    tag176: [],
    tag177: [],
    tag178: [],
    tag179: [],
    tag181: [],
    tag183: [],
    tag184: [],
    tag186: [],
  );

  // Fetch all drinks for the bar
  final url = Uri.parse('https://www.barzzy.site/bars/getAllDrinksByBar/$barId');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> jsonResponse = jsonDecode(response.body);
    debugPrint('Response received for bar $barId: $jsonResponse');

    for (var drinkJson in jsonResponse) {
      String? drinkId = drinkJson['drinkId']?.toString();
      if (drinkId != null) {
        // Deserialize the drink JSON into a Drink object
        Drink drink = Drink.fromJson(drinkJson);

        // Add the drink object to the local database
        barDatabase.addDrink(drink);

        // Check the tags and add the drinkId to the appropriate tag list in Categories
        for (String tagId in drink.tagId) {
          switch (int.parse(tagId)) {
            case 172:
              categories.tag172.add(int.parse(drinkId));
              break;
            case 173:
              categories.tag173.add(int.parse(drinkId));
              break;
            case 174:
              categories.tag174.add(int.parse(drinkId));
              break;
            case 175:
              categories.tag175.add(int.parse(drinkId));
              break;
            case 176:
              categories.tag176.add(int.parse(drinkId));
              break;
            case 177:
              categories.tag177.add(int.parse(drinkId));
              break;
            case 178:
              categories.tag178.add(int.parse(drinkId));
              break;
            case 179:
              categories.tag179.add(int.parse(drinkId));
              break;
            case 181:
              categories.tag181.add(int.parse(drinkId));
              break;
            case 183:
              categories.tag183.add(int.parse(drinkId));
              break;
            case 184:
              categories.tag184.add(int.parse(drinkId));
              break;
            case 186:
              categories.tag186.add(int.parse(drinkId));
              break;
            default:
              debugPrint('Unknown tagId: $tagId for drinkId: $drinkId');
          }
        }

        debugPrint('Added drink to database: ${drink.name} (ID: $drinkId)');
      } else {
        debugPrint('Warning: Drink ID is null for drink: $drinkJson');
      }
    }

    // Add the Categories object to the User map
    user.addCategories(barId, categories);

    debugPrint(
        'Drinks for bar $barId have been categorized and added to the User object.');
  } else {
    debugPrint('Failed to load drinks for bar $barId. Status code: ${response.statusCode}');
  }

  debugPrint('Finished processing drinks for barId: $barId');
}

class Barzzy extends StatelessWidget {
  final bool loggedInAlready;
  final bool isBar;
  final GlobalKey<NavigatorState> navigatorKey;

  const Barzzy({
    super.key,
   required this.loggedInAlready, 
   required this.isBar,
   required this.navigatorKey,
   });

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
      navigatorKey: navigatorKey,
      //theme: ThemeData.dark(),
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
