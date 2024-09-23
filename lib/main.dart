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
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barzzy_app1/Backend/localdatabase.dart';
import 'package:http/http.dart' as http;
import 'package:barzzy_app1/Backend/barhistory.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // Crashlytics


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("current date: ${DateTime.now()}");
  
if (Firebase.apps.isEmpty) {
  await Firebase.initializeApp();
   }
  // Enable Crashlytics collection for Flutter errors
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  final loginCache = LoginCache();
  bool loggedInAlready = true;
  await loginCache.getSignedIn();

  // Make HTTP request and initialize your application logic
  final url = Uri.parse('https://www.barzzy.site/signup/login');
  final initPW = await loginCache.getPW();
  final initEmail = await loginCache.getEmail();

  // Create the request body
  final requestBody = jsonEncode({'email': initEmail, 'password': initPW});
  bool httpRequest = false;

  // Send the POST request
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: requestBody,
  );

  // Check the response
  if (response.statusCode == 200) {
    debugPrint('Init Request successful');
    if (int.parse(response.body) != 0) httpRequest = true;
  } else {
    debugPrint('Init Request failed with status: ${response.statusCode}');
  }

  final uid = await loginCache.getUID();
  final isBar = uid < 0;
  loggedInAlready = loggedInAlready && httpRequest;

  LocalDatabase localDatabase = LocalDatabase();
  User user = User();
  await sendGetRequest();

  // Initialize the notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    onDidReceiveLocalNotification:
        (int id, String? title, String? body, String? payload) async {
      // Handle the notification tapped event when the app is in foreground
    },
  );

  final InitializationSettings initializationSettings =
      InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      if (response.payload != null && response.payload == 'app_started') {
        runApp(Barzzy(
          loggedInAlready: loggedInAlready,
          isBar: isBar,
          navigatorKey: navigatorKey,
        ));
      }
    },
  );

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

      final List<dynamic> jsonResponse = jsonDecode(response.body);
      LocalDatabase barDatabase = LocalDatabase();
      for (var barJson in jsonResponse) {
        Bar bar = Bar.fromJson(barJson);
        barDatabase.addBar(bar);

        if (bar.barimg != null && bar.barimg!.isNotEmpty) {
          final cachedImage = CachedNetworkImageProvider(bar.barimg!);
          cachedImage.resolve(const ImageConfiguration()).addListener(
            ImageStreamListener(
              (ImageInfo image, bool synchronousCall) {
                //debugPrint('Bar image successfully cached: ${bar.barimg}');
              },
              onError: (dynamic exception, StackTrace? stackTrace) {
                //debugPrint('Failed to cache bar image: $exception');
              },
            ),
          );
        }
        await fetchTagsAndDrinks(bar.id!);
      }
    } else {
      debugPrint('Failed to send GET request: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error sending GET request: $e');
  }
}

Future<void> fetchTagsAndDrinks(String barId) async {
  debugPrint('Fetching drinks for bar ID: $barId');
  LocalDatabase barDatabase = LocalDatabase();
  User user = User();


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

  final url = Uri.parse('https://www.barzzy.site/bars/getAllDrinksByBar/$barId');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> jsonResponse = jsonDecode(response.body);
    debugPrint('Drinks JSON response for bar $barId: $jsonResponse');

    for (var drinkJson in jsonResponse) {
      String? drinkId = drinkJson['drinkId']?.toString();
      debugPrint('Processing drink: $drinkJson');

      if (drinkId != null) {
        Drink drink = Drink.fromJson(drinkJson);
        barDatabase.addDrink(drink);
        debugPrint('Added drink with ID: $drinkId to bar $barId');

        if (drink.image.isNotEmpty) {
          final cachedImage = CachedNetworkImageProvider(drink.image);
          cachedImage.resolve(const ImageConfiguration()).addListener(
            ImageStreamListener(
              (ImageInfo image, bool synchronousCall) {
                debugPrint('Drink image successfully cached: ${drink.image}');
              },
              onError: (dynamic exception, StackTrace? stackTrace) {
                debugPrint('Failed to cache drink image: $exception');
              },
            ),
          );
        }

        for (String tagId in drink.tagId) {
          debugPrint('Processing tagId: $tagId for drinkId: $drinkId');
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
      } else {
        debugPrint('Warning: Drink ID is null for drink: $drinkJson');
      }
    }

    user.addCategories(barId, categories);
    debugPrint('Drinks for bar $barId have been categorized and added to the User object.');
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
    Provider.of<Recommended>(context, listen: false).fetchRecommendedBars(context);

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
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: {
        '/auth': (context) => const AuthPage(),
        '/bar': (context) => const BartenderIDScreen(),
        '/login': (context) => const LoginOrRegisterPage(),
        '/orders': (context) => const AuthPage(selectedTab: 1),
      },
    );
  }
}