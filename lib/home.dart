import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:barzzy_app1/backend/bardatabase.dart';
import 'package:barzzy_app1/components/barhistory.dart';
import 'package:barzzy_app1/components/hometopicons.dart';
import 'package:barzzy_app1/menu.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, });

  @override
  Widget build(BuildContext context) {
    final barHistory = Provider.of<BarHistory>(context);
    final barDatabase = Provider.of<BarDatabase>(context);

    List<String> historyIds = barHistory.historyIds;
    int historyLength = historyIds.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: const BoxDecoration(
              border: Border(
              bottom: BorderSide(color: Color.fromARGB(255, 126, 126, 126), width: 0.0425),
              ),
            ),
            padding: const EdgeInsets.only(bottom: 8.29),
              child: const MyTopIcons(),
            ),
            if (historyLength > 1)
              Padding(
                padding: const EdgeInsets.only(
                  top: 11.5, 
                  left: 5),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 12),
                    height: 97.5,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Color.fromARGB(255, 126, 126, 126),
                          width: 0.1,
                        ),
                      ),
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: historyLength - 1,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MenuPage(barId: historyIds[index + 1]),
                            ),
                          ),
                          child: Container(
                            width: 85,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 0, 0, 0),
                              border: Border.all(
                                color: Colors.white, 
                                width: .5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                barDatabase.getBarById(historyIds[index + 1])?.name ?? 'No Name',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            if (historyLength > 0)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MenuPage(barId: historyIds[0]),
                  ),
                ),
                child: Container(
                  height: 400,
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      barDatabase.getBarById(historyIds[0])?.name ?? 'No Recent Bar',
                      style: const TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            if (historyLength > 0)
              Container(
                height: 30,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 17.5),
                      child: Text(
                        'Open',
                        style: GoogleFonts.sourceSans3(
                          fontSize: 15,
                          color: Colors.lightGreen,
                        ),
                      ),
                    ),
                    Text(
                      'Wait time: 5 min',
                      style: GoogleFonts.sourceSans3(
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.black,
                          builder: (BuildContext context) {
                            double screenHeight = MediaQuery.of(context).size.height;
                            double bottomSheetHeight = screenHeight * 0.75; // Set the height to 80% of the screen height

                            return Container(
                              height: bottomSheetHeight,
                              width: double.infinity,
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  
                                  Container(
                                    width: 150,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.5), // Set color and opacity
                                      borderRadius: BorderRadius.circular(20), // Make it circular
                                    ),
                                  ),
                                  
                                  
                                  // Add more widgets as needed
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}