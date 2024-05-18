import 'package:barzzy_app1/HomePage/bottomsheet.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:barzzy_app1/Backend/bardatabase.dart';
import 'package:barzzy_app1/Extra/barhistory.dart';
import 'package:barzzy_app1/HomePage/hometopicons.dart';
import 'package:barzzy_app1/MenuPage/menu.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final barHistory = Provider.of<BarHistory>(context);
    final barDatabase = Provider.of<BarDatabase>(context);

    List<String> historyIds = barHistory.historyIds;
    int historyLength = historyIds.length;

    void showBottomSheet(BuildContext context, String barId) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.black,
        builder: (BuildContext context) {
          return BarBottomSheet(barId: barId);
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                                                                          // STAGE 1 ***Default Does Not Appear***

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            // BORDERED TOP ICONS

            if (historyLength == 0)
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: Color.fromARGB(255, 126, 126, 126),
                        width: 0.0425),
                  ),
                ),
                padding: const EdgeInsets.only(bottom: 8.29),
                child: const MyTopIcons(),
              ),

            // FIND YOUR BAR

            if (historyLength == 0)
              const Padding(
                padding: EdgeInsets.only(top: 300),
                child: Center(child: Text('FIND YOUR BAR')),
              ),

                                                                          // STAGE 2 ***Default Does Appear***

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            // NON-BORDERED TOP ICONS

            if (historyLength > 0)
              Container(
                padding: const EdgeInsets.only(bottom: 8.29),
                child: const MyTopIcons(),
              ),

            // EMPTY RECENTS DISPLAY

            if (historyLength == 1)
              Padding(
                padding: const EdgeInsets.only(left: 5.5),
                child: Container(
                  padding: const EdgeInsets.only(bottom: 15),
                  height: 128,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Color.fromARGB(255, 126, 126, 126),
                        width: 0.1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 85,
                            height: 85,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 0, 0, 0),
                              border: Border.all(
                                color: Colors.white,
                                width: .5,
                              ),
                              borderRadius: BorderRadius.circular(60),
                            ),
                            child: const Text(''),
                          ),
                          const SizedBox(height: 2.9),
                           Text(
                            'Recents',
                            style: GoogleFonts.sourceSans3(
                          fontSize: 15.25,
                          color: Colors.white,
                        ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

                                                                          // STAGE 3

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            //  ACTIVE RECENT BARS DISPLAY   ***Uses Previous Stages Top Icons***

            if (historyLength > 1)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Container(
                  padding: const EdgeInsets.only(bottom: 15),
                  height: 128, // Adjusted height to fit the name below
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
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          showBottomSheet(context, historyIds[index + 1]);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 85,
                              height: 85,
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 0, 0, 0),
                                border: Border.all(
                                  color: Colors.white,
                                  width: .5,
                                ),
                                borderRadius: BorderRadius.circular(60),
                              ),
                              child: const Text(''),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              barDatabase
                                      .getBarById(historyIds[index + 1])
                                      ?.tag ??
                                  'No Name',
                              style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 12, 
                              )
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 17.5),

                                                                          // DEFAULT

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            // TOP ROW WITH BAR NAME AND WAIT TIME

            if (historyLength > 0)
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Padding(
                  padding: const EdgeInsets.only(left: 27),
                  child: Text(
                    barDatabase.getBarById(historyIds[0])?.name ?? 'No Name',
                    style: const TextStyle(
                          color: Colors.white,
                          //fontWeight: FontWeight.w500
                        ),
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    showBottomSheet(context, historyIds[0]);
                  },
                  child: const Padding(
                    padding:  EdgeInsets.only(right: 27),
                    child: Icon(
                      Icons.history_rounded,
                      color: Colors.grey,
                      size: 30,
                    ),
                  ),
                ),

              ]),

            // MAIN MOST RECENT BAR

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
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(
                    child: Text(
                      'Picture',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),

            //BOTTOM ROW WITH RECENT DRINKS AND WAIT TIME

            if (historyLength > 0)
              Container(
                height: 30,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 27),
                      child: RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Open',
                              style: TextStyle(
                                color: Colors.green,
                                //fontWeight: FontWeight.w500
                              ),
                            ),
                            TextSpan(
                              text: ' / ',
                              style: TextStyle(
                                fontSize: 17.5,
                                color: Colors.white,
                                //fontWeight: FontWeight.w500
                              ),
                            ),
                            TextSpan(
                              text: 'Closed',
                              style: TextStyle(
                                color: Colors.grey,
                                //fontWeight: FontWeight.w500
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                     const Padding(
                      padding: EdgeInsets.only(right: 27),
                      child: Text(
                        'Wait: 10 min',
                        style: TextStyle(
                          color: Colors.white,
                          //fontWeight: FontWeight.w500
                        ),
                      ),
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
