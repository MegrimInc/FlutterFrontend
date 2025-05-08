import 'dart:convert';
import 'package:barzzy/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy/AuthPages/components/toggle.dart';
import 'package:barzzy/Backend/merchant.dart';
import 'package:barzzy/Backend/customer.dart';
import 'package:barzzy/Backend/searchengine.dart';
import 'package:barzzy/Backend/recommended.dart';
import 'package:barzzy/Backend/preferences.dart';
import 'package:barzzy/Gnav%20Bar/bottombar.dart';
import 'package:barzzy/MenuPage/cart.dart';
import 'package:barzzy/MenuPage/itemfeed.dart';
import 'package:barzzy/MenuPage/menu.dart';
import 'package:barzzy/OrdersPage/websocket.dart';
import 'package:barzzy/Terminal/inventory.dart';
import 'package:barzzy/Terminal/select.dart';
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
import 'package:barzzy/Backend/merchanthistory.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // Crashlytics
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'config.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("current date: ${DateTime.now()}");

  // Stripe.publishableKey =
  //     'pk_live_51QIHPQALmk8hqurj9QQVsCMabyzQ3hCJrxk1PhLNJFXDHfbmQqkJzEdOIrXlGd27hBEJchOuLBjIrb6WKxKiUKoo00tOVyaRdA';

  Stripe.publishableKey =
      'sk_test_51QIHPQALmk8hqurj69ipiDbnAGd0ELb4l1Nt8fF359rSzFmY7bUHAXClqNytoqv7cpATWNuvymfEEUICGY7bPfd700tIvIIkIY';

  AppConfig.environment = Environment.test;
  

  Stripe.merchantIdentifier = 'merchant.com.barzzy'; //TODO CHECK THIS CHIDE

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
    debugPrint('Customer granted permission');
  } else {
    debugPrint('Customer declined or has not accepted permission');
  }

  // Retrieve and print the device token
  String? deviceToken = await messaging.getAPNSToken();
  debugPrint("Device Token: $deviceToken");
  deviceToken = deviceToken ?? '';

  final loginCache = LoginCache();
  bool loggedInAlready = true;
  await loginCache.getSignedIn();

  // Make HTTP request and initialize your application logic
  final url = Uri.parse('${AppConfig.postgresApiBaseUrl}/auth/login-customer');
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
    final serverUID =
        int.parse(response.body); // Get the UID from server response
    if (serverUID != 0) {
      httpRequest = true;
      await loginCache.setUID(serverUID); // Update the UID in LoginCache
    }
  } else {
    debugPrint('Init Request failed with status: ${response.statusCode}');
  }

  final uid = await loginCache.getUID();
  final isMerchant = uid < 0;
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
        ChangeNotifierProvider(create: (context) => MerchantHistory()),
        ChangeNotifierProvider(create: (context) => Recommended()),
        ChangeNotifierProvider(create: (_) => Inventory()),
        ChangeNotifierProvider(
            create: (context) => Hierarchy(context, navigatorKey)),
        ChangeNotifierProvider(create: (_) => LoginCache()),
        ChangeNotifierProvider(create: (context) => Customer()),
        ProxyProvider<LocalDatabase, SearchService>(
          update: (_, localDatabase, __) => SearchService(localDatabase),
        ),
      ],
      child: Barzzy(
        loggedInAlready: loggedInAlready,
        isMerchant: isMerchant,
        navigatorKey: navigatorKey,
      ),
    ),
  );
}

Future<void> sendGetRequest() async {
  try {
    final url = Uri.parse('${AppConfig.postgresApiBaseUrl}/customer/seeAllMerchants');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      debugPrint('GET request successful');

      final List<dynamic> jsonResponse = jsonDecode(response.body);
      LocalDatabase localDatabase = LocalDatabase();
      for (var merchantJson in jsonResponse) {
         debugPrint('Merchant JSON data: ${jsonEncode(merchantJson)}');
        Merchant merchant = Merchant.fromJson(merchantJson);
        localDatabase.addMerchant(merchant);

        if (merchant.merchantimg != null && merchant.merchantimg!.isNotEmpty) {
          final cachedImage = CachedNetworkImageProvider(merchant.merchantimg!);
          cachedImage.resolve(const ImageConfiguration()).addListener(
                ImageStreamListener(
                  (ImageInfo image, bool synchronousCall) {
                    //debugPrint('Merchant image successfully cached: ${merchant.merchantimg}');
                  },
                  onError: (dynamic exception, StackTrace? stackTrace) {
                    //debugPrint('Failed to cache merchant image: $exception');
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
    // Add or update points in the LocalDatabase for each merchant
    LocalDatabase localDatabase = LocalDatabase();

    final loginCache = LoginCache();
    final customerId = await loginCache.getUID();

    if (customerId == 0) {
      debugPrint('Customer Id is 0, skipping GET request for points.');
      return;
    }

    final url = Uri.parse('${AppConfig.postgresApiBaseUrl}/customer/points/$customerId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      debugPrint('GET request for points successful: ${response.body}');

      // Parse the response body into a Map
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      debugPrint('Decoded JSON response: $jsonResponse');

      if (jsonResponse.isEmpty ||
          !jsonResponse.containsKey(customerId.toString())) {
        debugPrint('No points found, clearing the points map.');
        localDatabase.clearPoints();
        return;
      }

      // Check if the customer Id from the response matches the one in LoginCache
      final String customerIdString = customerId.toString();
      if (!jsonResponse.containsKey(customerIdString)) {
        debugPrint('Customer Id from response does not match the logged-in customer.');
        return;
      }

      // Get the points map for the customer (merchantId -> points)
      final Map<String, dynamic> customerPointsMap = jsonResponse[customerIdString];

      // Iterate over the customer points map (merchantId -> points)
      customerPointsMap.forEach((merchantId, points) {
        try {
          final Point point = Point(merchantId: merchantId.toString(), points: points);
          debugPrint(
              'Successfully serialized Point: Merchant Id: ${point.merchantId}, Points: ${point.points}');

          // Add or update the points in the LocalDatabase
          localDatabase.addOrUpdatePoints(point.merchantId, point.points);
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

Future<void> sendGetRequest3() async {
  final loginCache = LoginCache();
  LocalDatabase localDatabase = LocalDatabase();
  final customerId = await loginCache.getUID();

  // Construct the URL to your backend endpoint – adjust the URL as necessary.
  final url = Uri.parse('${AppConfig.postgresApiBaseUrl}/customer/cardDetails/$customerId');

  try {
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      // Parse the JSON response
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      // Create a Customer instance from the JSON data
      Customer customer = Customer.fromJson(jsonResponse);
      localDatabase.setCustomer(customer);

      debugPrint("Saved customer: $customer in LocalDatabase");
    } else {
      debugPrint(
          "Failed to retrieve card details, status: ${response.statusCode}");
    }
  } catch (e) {
    debugPrint("Error in sendGetRequest3: $e");
  }
}

class Barzzy extends StatelessWidget {
  final bool loggedInAlready;
  final bool isMerchant;
  final GlobalKey<NavigatorState> navigatorKey;

  const Barzzy({
    super.key,
    required this.loggedInAlready,
    required this.isMerchant,
    required this.navigatorKey,
  });

  @override
  Widget build(BuildContext context) {
    Provider.of<MerchantHistory>(context, listen: false).setContext(context);
    Provider.of<Recommended>(context, listen: false)
        .fetchRecommendedMerchants(context);

    final String initialRoute;
    if (!loggedInAlready) {
      initialRoute = '/login';
    } else if (isMerchant) {
      initialRoute = '/merchant';
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
        '/merchant': (context) => const TerminalIdScreen(),
        '/login': (context) => const LoginOrRegisterPage(),
        '/orders': (context) => const AuthPage(selectedTab: 1),
        '/menu': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          final String merchantId = args['merchantId'];
          final Cart cart = args['cart'];
          final String? itemId = args['itemId']; // Optional parameter
          final String? claimer = args['claimer'];

          return MenuPage(
            merchantId: merchantId,
            cart: cart,
            itemId: itemId, // Pass the optional itemId
            claimer: claimer,
          );
        },
        '/itemFeed': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return ItemFeed(
            item: args['item'],
            cart: args['cart'],
            merchantId: args['merchantId'],
            initialPage: args['initialPage'],
            claimer: args['claimer'],
          );
        },
      },
    );
  }
}