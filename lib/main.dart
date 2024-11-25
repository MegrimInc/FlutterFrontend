import 'dart:convert';
import 'package:barzzy/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy/AuthPages/components/toggle.dart';
import 'package:barzzy/Backend/bar.dart';
import 'package:barzzy/Backend/searchengine.dart';
import 'package:barzzy/Backend/recommended.dart';
import 'package:barzzy/Backend/user.dart';
import 'package:barzzy/Gnav%20Bar/bottombar.dart';
import 'package:barzzy/MenuPage/cart.dart';
import 'package:barzzy/MenuPage/drinkfeed.dart';
import 'package:barzzy/MenuPage/menu.dart';
import 'package:barzzy/OrdersPage/websocket.dart';
import 'package:barzzy/Terminal/stationid.dart';
import 'package:barzzy/Backend/point.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barzzy/Backend/localdatabase.dart';
import 'package:http/http.dart' as http;
import 'package:barzzy/Backend/barhistory.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // Crashlytics
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("current date: ${DateTime.now()}");

  Stripe.publishableKey =
      'pk_test_51QIHPQALmk8hqurjW70pr2kLZg1lr0bXN9K6uMdf9oDPwn3olIIPRd2kJncr8rGMKjVgSUsZztTtIcPwDlLfchgu00dprIZKma';
  Stripe.merchantIdentifier = 'merchant.com.barzzy';

  try {
    debugPrint("Starting Firebase Initialization");

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint("Firebase Initialization Completed");
  } catch (e) {
    debugPrint("Firebase Initialization Failed: $e");
  }

  // Enable Crashlytics collection for Flutter errors
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permissions for iOS devices
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    debugPrint('User granted permission');
  } else {
    debugPrint('User declined or has not accepted permission');
  }

  // Retrieve and print the device token
  String? deviceToken = await messaging.getAPNSToken();
  debugPrint("Device Token: $deviceToken");
  deviceToken = deviceToken ?? '';

  final loginCache = LoginCache();
  bool loggedInAlready = true;
  await loginCache.getSignedIn();

  // Make HTTP request and initialize your application logic
  final url = Uri.parse('https://www.barzzy.site/newsignup/login');
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
  await loginCache.setDeviceToken(deviceToken);
  LocalDatabase localDatabase = LocalDatabase();
  await sendGetRequest();
  await sendGetRequest2();

  // Create the MethodChannel
  const MethodChannel notificationChannel =
      MethodChannel('com.barzzy/notification');

  // Set up a listener for when the notification is tapped
  notificationChannel.setMethodCallHandler((MethodCall call) async {
    if (call.method == 'navigateToOrders') {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/orders',
        (Route<dynamic> route) => false, // This removes all previous routes.
      );
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => localDatabase),
        ChangeNotifierProvider(create: (context) => BarHistory()),
        ChangeNotifierProvider(create: (context) => Recommended()),
        ChangeNotifierProvider(
            create: (context) => Hierarchy(context, navigatorKey)),
        ChangeNotifierProvider(create: (_) => LoginCache()),
        ChangeNotifierProvider(create: (context) => User()),
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
      LocalDatabase localDatabase = LocalDatabase();
      for (var barJson in jsonResponse) {
        Bar bar = Bar.fromJson(barJson);
        debugPrint('Bar JSON data: ${jsonEncode(barJson)}');
        localDatabase.addBar(bar);

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
      }
    } else {
      debugPrint('Failed to send GET request: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error sending GET request: $e');
  }
}

Future<void> sendGetRequest2() async {
  try {
    // Add or update points in the LocalDatabase for each bar
    LocalDatabase localDatabase = LocalDatabase();

    final loginCache = LoginCache();
    final userId = await loginCache.getUID();

    if (userId == 0) {
      debugPrint('User ID is 0, skipping GET request for points.');
      return;
    }

    final url = Uri.parse('https://www.barzzy.site/customer/points/$userId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      debugPrint('GET request for points successful: ${response.body}');

      // Parse the response body into a Map
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      debugPrint('Decoded JSON response: $jsonResponse');

      if (jsonResponse.isEmpty ||
          !jsonResponse.containsKey(userId.toString())) {
        debugPrint('No points found, clearing the points map.');
        localDatabase.clearPoints();
        return;
      }

      // Check if the user ID from the response matches the one in LoginCache
      final String userIdString = userId.toString();
      if (!jsonResponse.containsKey(userIdString)) {
        debugPrint('User ID from response does not match the logged-in user.');
        return;
      }

      // Get the points map for the user (barId -> points)
      final Map<String, dynamic> userPointsMap = jsonResponse[userIdString];

      // Iterate over the user points map (barId -> points)
      userPointsMap.forEach((barId, points) {
        try {
          final Point point = Point(barId: barId.toString(), points: points);
          debugPrint(
              'Successfully serialized Point: Bar ID: ${point.barId}, Points: ${point.points}');

          // Add or update the points in the LocalDatabase
          localDatabase.addOrUpdatePoints(point.barId, point.points);
        } catch (e) {
          debugPrint('Error serializing Point object from JSON: $e');
        }
      });
    } else {
      debugPrint(
          'Failed to send GET request for points: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error sending GET request for points: $e');
  }
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
      theme: ThemeData(
    cupertinoOverrideTheme: const CupertinoThemeData(
      primaryColor: Colors.grey, // For iOS selector pins
    ),
    textSelectionTheme: const TextSelectionThemeData(
      selectionColor: Colors.grey, // Text selection highlight color
      selectionHandleColor: Colors.grey, // Selection handle color (Android)
    ),
  ),
      initialRoute: initialRoute,
      routes: {
        '/auth': (context) => const AuthPage(),
        '/bar': (context) => const BartenderIDScreen(),
        '/login': (context) => const LoginOrRegisterPage(),
        '/orders': (context) => const AuthPage(selectedTab: 1),
        '/menu': (context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final String barId = args['barId'];
    final Cart cart = args['cart'];
    final String? drinkId = args['drinkId']; // Optional parameter

    return MenuPage(
      barId: barId,
      cart: cart,
      drinkId: drinkId, // Pass the optional drinkId
    );
  },
  '/drinkFeed': (context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    return DrinkFeed(
      drink: args['drink'],
      cart: args['cart'],
      barId: args['barId'],
      initialPage: args['initialPage'],
    );
  },
      },
    );
  }
}
