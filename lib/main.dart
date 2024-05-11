import 'package:barzzy_app1/backend/searchengine.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barzzy_app1/backend/bardatabase.dart';
import 'package:barzzy_app1/backend/filereader.dart';
import 'package:barzzy_app1/components/auth.dart';
import 'package:barzzy_app1/components/barhistory.dart';

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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthPage(),
    );
  }
}