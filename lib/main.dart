import 'dart:convert';
import 'package:barzzy_app1/AuthPages/LoginPage/login.dart';
import 'package:barzzy_app1/AuthPages/RegisterPages/httpservicev2.dart';
import 'package:barzzy_app1/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy_app1/Backend/bar.dart';
import 'package:barzzy_app1/Backend/drink.dart';
import 'package:barzzy_app1/Backend/searchengine.dart';
import 'package:barzzy_app1/Backend/recommended.dart';
import 'package:barzzy_app1/Backend/tags.dart';
import 'package:barzzy_app1/Backend/user.dart';
import 'package:barzzy_app1/HomePage/home.dart';
import 'package:barzzy_app1/QrPage/camera.dart';
import 'package:flutter/material.dart';
import 'package:mailer/smtp_server.dart';
import 'package:provider/provider.dart';
import 'package:barzzy_app1/Backend/bardatabase.dart';
import 'package:http/http.dart' as http;
import 'package:barzzy_app1/Extra/auth.dart';
import 'package:barzzy_app1/Backend/barhistory.dart';
//import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:barzzy_app1/Backend/cache.dart';


void main() async { 
print("current date: ${DateTime.now()}");

/*print("attempting email send");
  var rng = Random();
  String verificationCode = rng.nextInt(9).toString() + rng.nextInt(9).toString() + rng.nextInt(9).toString() + rng.nextInt(9).toString() + rng.nextInt(9).toString() + rng.nextInt(9).toString();
print("verification code genned: $verificationCode");
  final smtpServer = SmtpServer("email-smtp.us-east-1.amazonaws.com", port: 25, username: "AKIARKMXJUVKGK3ZC6FH", password: "BJ0EwGiCXsXWcZT2QSI5eR+5yFzbimTnquszEXPaEXsd");
print("SMTP SERVER CREATED");
  final username = "donotreply@barzzy.site";
  final msg = Message()
  ..from = Address(username, 'Barzzy Official')
  ..recipients.add(Address('chidereyaogan@gmail.com'))
  ..subject = 'Barzzy Email Verification Code | ${DateTime.now()}'
  ..text = 'Your verification code is: $verificationCode';
print('Message generated');
  try {
    final sendReport = await send(msg, smtpServer);
print('Message sent: ' + sendReport.toString());
  } on MailerException catch (e) {
print('Message not sent. mailerexception msg: ' + e.message);
    for (var p in e.problems) {
print('Problem: ${p.code}: ${p.msg}');
    }
    } catch (e, stackTrace) {
    print('An error occurred: ${e.toString()}');
    print('Stack trace: ${stackTrace.toString()}');
  }

print("email send attempt done");
*/

/*
final test = HttpService();
print(test.hello());
*/






  WidgetsFlutterBinding.ensureInitialized();
  final loginCache3 = LoginCache();
  bool loggedInAlready = await loginCache3.getSignedIn() /* && HTTP REQUEST*/;
  BarDatabase barDatabase = BarDatabase();
  //Stripe.publishableKey = 'your_stripe_key_here';
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
      child: Barzzy(loggedInAlready: loggedInAlready,),
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
  final bool loggedInAlready;
  const Barzzy({super.key, required this.loggedInAlready});

  @override
  Widget build(BuildContext context) {
    Provider.of<BarHistory>(context, listen: false).setContext(context);
    Provider.of<Recommended>(context, listen: false)
        .fetchRecommendedBars(context);
        
    cameraControllerSingleton.initialize();
    return MaterialApp(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: loggedInAlready ? const AuthPage() : LoginPage(onTap: () => {})//Make it so that when bars sign in, they get sent to
      //home: const AuthPage(),
    );
  }
}
