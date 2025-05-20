import 'dart:convert';
import 'dart:io';
import 'package:barzzy/DTO/config.dart';
import 'package:barzzy/UI/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy/UI/AuthPages/components/toggle.dart';
import 'package:barzzy/Backend/database.dart';
import 'package:barzzy/DTO/merchant.dart';
import 'package:barzzy/DTO/customer.dart';
import 'package:barzzy/Backend/searchengine.dart';
import 'package:barzzy/Backend/recommended.dart';
import 'package:barzzy/UI/BottomBar/bottombar.dart';
import 'package:barzzy/Backend/cart.dart';
import 'package:barzzy/UI/CatalogPage/catalog.dart';
import 'package:barzzy/UI/CheckoutPage/checkout.dart';
import 'package:barzzy/Backend/websocket.dart';
import 'package:barzzy/UI/TerminalPages/inventory.dart';
import 'package:barzzy/UI/TerminalPages/select.dart';
import 'package:barzzy/DTO/point.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:http/http.dart' as http;
import 'package:barzzy/Backend/history.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // Crashlytics
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'config.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const String currentIOSMobileVersion = '1.9.0'; // Define your app version here
const String currentIOSTabletVersion = '0.0.0'; // Define tablet version if different


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.environment = Environment.test;

  Stripe.publishableKey = AppConfig.stripePublishableKey;

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
    debugPrint('Customer granted permission');
  } else {
    debugPrint('Customer declined or has not accepted permission');
  }

  // Retrieve and print the device token
  String? deviceToken = await messaging.getAPNSToken();
  debugPrint("Device Token: $deviceToken");
  deviceToken = deviceToken ?? '';

  LocalDatabase localDatabase = LocalDatabase();


  await fetchConfig();

  WidgetsBinding.instance.addPostFrameCallback((_) async {
  await AppConfig().enforceVersionPolicy(navigatorKey.currentContext!);
  });

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

  await sendGetMerchants();
  await sendGetPoints();

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
            create: (context) => Websocket(context, navigatorKey)),
        ChangeNotifierProvider(create: (_) => LoginCache()),
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

Future<void> fetchConfig() async {
  try {
    final url = Uri.parse('${AppConfig.postgresApiBaseUrl}/config');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      final config = Config.fromJson(jsonResponse);

      LocalDatabase().setConfig(config);
      debugPrint("Config fetched and stored: \$config");
    } else {
      debugPrint("Failed to fetch config: \${response.statusCode}");
    }
  } catch (e) {
    debugPrint("Error fetching config: \$e");
  }
}

Future<void> sendGetMerchants() async {
  try {
    final url =
        Uri.parse('${AppConfig.postgresApiBaseUrl}/customer/seeAllMerchants');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      debugPrint('GET request successful');

      final List<dynamic> jsonResponse = jsonDecode(response.body);
      LocalDatabase localDatabase = LocalDatabase();
      for (var merchantJson in jsonResponse) {
        debugPrint('Merchant JSON data: ${jsonEncode(merchantJson)}');
        Merchant merchant = Merchant.fromJson(merchantJson);
        localDatabase.addMerchant(merchant);

        if (merchant.storeImg != null && merchant.storeImg!.isNotEmpty) {
          final cachedImage = CachedNetworkImageProvider(merchant.storeImg!);
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

Future<void> sendGetPoints() async {
  try {
    // Add or update points in the LocalDatabase for each merchant
    LocalDatabase localDatabase = LocalDatabase();

    final loginCache = LoginCache();
    final customerId = await loginCache.getUID();

    if (customerId == 0) {
      debugPrint('Customer Id is 0, skipping GET request for points.');
      return;
    }

    final url = Uri.parse(
        '${AppConfig.postgresApiBaseUrl}/customer/points/$customerId');
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
        debugPrint(
            'Customer Id from response does not match the logged-in customer.');
        return;
      }

      // Get the points map for the customer (merchantId -> points)
      final Map<String, dynamic> customerPointsMap =
          jsonResponse[customerIdString];

      // Iterate over the customer points map (merchantId -> points)
      customerPointsMap.forEach((merchantId, points) {
        try {
          final Point point =
              Point(merchantId: int.parse(merchantId), points: points);
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

Future<void> getCardDetails() async {
  final loginCache = LoginCache();
  LocalDatabase localDatabase = LocalDatabase();
  final customerId = await loginCache.getUID();

  // Construct the URL to your backend endpoint – adjust the URL as necessary.
  final url = Uri.parse(
      '${AppConfig.postgresApiBaseUrl}/customer/cardDetails/$customerId');

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

Future<void> detectIOSDeviceType() async {
  if (Platform.isIOS) {
    final deviceInfo = DeviceInfoPlugin();
    final iosInfo = await deviceInfo.iosInfo;
    final model = iosInfo.utsname.machine;

    if (model.toLowerCase().contains('ipad')) {
      debugPrint('This is an iPad.');
    } else if (model.toLowerCase().contains('iphone')) {
      debugPrint('This is an iPhone.');
    } else {
      debugPrint('Unknown iOS device: $model');
    }
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
          final int merchantId = args['merchantId'];
          final Cart cart = args['cart'];
          final int? itemId = args['itemId']; // Optional parameter
          final String? terminal = args['terminal'];

          return CatalogPage(
            merchantId: merchantId,
            cart: cart,
            itemId: itemId, // Pass the optional itemId
            terminal: terminal,
          );
        },
        '/itemFeed': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return CheckoutPage(
            item: args['item'],
            cart: args['cart'],
            merchantId: args['merchantId'],
            initialPage: args['initialPage'],
            terminal: args['terminal'],
          );
        },
      },
    );
  }
}
