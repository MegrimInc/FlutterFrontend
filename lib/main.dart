import 'package:barzzy_app1/Backend/searchengine.dart';
import 'package:barzzy_app1/Backend/recommended.dart';
import 'package:barzzy_app1/Backend/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barzzy_app1/Backend/bardatabase.dart';
import 'package:barzzy_app1/Backend/filereader.dart';
import 'package:barzzy_app1/Extra/auth.dart';
import 'package:barzzy_app1/Backend/barhistory.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  BarDatabase barDatabase = BarDatabase();
  FileReader fileReader = FileReader(barDatabase);

  await fileReader.loadMenu(); // Load the menu data at startup


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => barDatabase),
        ChangeNotifierProvider(create: (context) => BarHistory()),
        ChangeNotifierProvider(create: (context) => Recommended()),
        // Provider<User>(
        //   create: (_) => User(), // Create an instance of the User class
        // ), 
        ChangeNotifierProvider(create: (context) => User()),
        
        ProxyProvider<BarDatabase, SearchService>(
          update: (_, barDatabase, __) => SearchService(barDatabase),)
      ],
      child: const Barzzy(),
    ),
  );
}

class Barzzy extends StatelessWidget {
  const Barzzy({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      //home: const ActionSheet(),
      home: const AuthPage(),
    );
  }
}