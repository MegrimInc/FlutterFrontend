import 'dart:convert';
import 'package:barzzy_app1/Backend/bar.dart';
import 'package:barzzy_app1/Backend/drink.dart';
import 'package:barzzy_app1/Backend/searchengine.dart';
import 'package:barzzy_app1/Backend/recommended.dart';
import 'package:barzzy_app1/Backend/tags.dart';
import 'package:barzzy_app1/Backend/user.dart';
import 'package:barzzy_app1/QrPage/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barzzy_app1/Backend/bardatabase.dart';
import 'package:http/http.dart' as http;
import 'package:barzzy_app1/Extra/auth.dart';
import 'package:barzzy_app1/Backend/barhistory.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:barzzy_app1/Backend/cache.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   BarDatabase barDatabase = BarDatabase();
//   Stripe.publishableKey = 'pk_test_51Pdz2ORv9bn5Mu1cyCLYFl9aygTs1VP6vMBfhKwoRldfoxqPmBoXtghmHVrFBe1wbWzfPRc2ok6eAZyJQQkYvKdu008i3gdtg1';
//   await sendGetRequest();
//   await fetchTags();
//   await updateDrinkDatabase(barDatabase);

//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (context) => barDatabase),
//         ChangeNotifierProvider(create: (context) => BarHistory()),
//         ChangeNotifierProvider(create: (context) => Recommended()),
//         ChangeNotifierProvider(create: (context) => User()),
//         ProxyProvider<BarDatabase, SearchService>(
//           update: (_, barDatabase, __) => SearchService(barDatabase),
//         )
//       ],
//       child: const Barzzy(),
//     ),
//   );
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  BarDatabase barDatabase = BarDatabase();
  Stripe.publishableKey = 'your_stripe_key_here';
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
        ChangeNotifierProvider(create: (context) => user),
        ProxyProvider<BarDatabase, SearchService>(
          update: (_, barDatabase, __) => SearchService(barDatabase),
        ),
      ],
      child: const Barzzy(),
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
      //debugPrint('Decoded JSON response: ${jsonResponse.toString()}');

      BarDatabase barDatabase = BarDatabase();
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
      BarDatabase barDatabase = BarDatabase();

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

Future<void> updateDrinkDatabase(BarDatabase barDatabase) async {
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
  const Barzzy({super.key});

  @override
  Widget build(BuildContext context) {
    Provider.of<BarHistory>(context, listen: false).setContext(context);
    Provider.of<Recommended>(context, listen: false)
        .fetchRecommendedBars(context);
    cameraControllerSingleton.initialize();
    return MaterialApp(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      //home: Testing()
      home: const AuthPage(),
    );
  }
}
