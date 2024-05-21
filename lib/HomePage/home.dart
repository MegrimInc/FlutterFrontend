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
          return BarBottomSheet(
            barId: barId,
            barHistory: barHistory
            );
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

            // LIST OF ALL BARS
            if (historyLength == 0)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: barDatabase.getSearchableBarInfo().entries.map((entry) {
                    final barId = entry.key;
                    final barInfo = entry.value;
                    return ListTile(
                      title: Text(
                        barInfo['name'] ?? 'No Name',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        barInfo['address'] ?? 'No Address',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MenuPage(barId: barId),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
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
                          fontSize: 12,
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
            const SizedBox(height: 20),

                                                                          // DEFAULT

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            // TOP ROW WITH BAR NAME AND WAIT TIME

            if (historyLength > 0 && !barHistory.isBarPinned(historyIds[0]))
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Padding(
                  padding: const EdgeInsets.only(left: 27),
                  child: Text(
                    barDatabase.getBarById(historyIds[0])?.name ?? 'No Name',
                    style: const TextStyle(
                          color: Colors.white,
                        ),
                  ),
                ),
               Padding(
                  padding: const EdgeInsets.only(right: 17),
                  child: IconButton(
                                icon: const Icon(Icons.history_rounded, 
                                size: 30,
                                color: Colors.grey,),
                                onPressed: () {
                  showBottomSheet(context, historyIds[0]);
                  }
                                ),
                ),
              ]),

            // MAIN MOST RECENT BAR

            if (historyLength > 0 && !barHistory.isBarPinned(historyIds[0]))
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MenuPage(barId: historyIds[0]),
                  ),
                ),
                child: Container(
                  height: 350,
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
            const SizedBox(height: 20),

            //BOTTOM ROW WITH RECENT DRINKS AND WAIT TIME

            if (historyLength > 0 && !barHistory.isBarPinned(historyIds[0]))
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
                                fontWeight: FontWeight.bold
                              ),
                            ),
                            TextSpan(
                              text: ' / ',
                              style: TextStyle(
                                fontSize: 17.5,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                            TextSpan(
                              text: 'Closed',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w700
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),


              //TEST ///////////////////////////////////////////////////////////////////////



if (historyLength > 0 && barHistory.isBarPinned(historyIds[0]))
  Container(
    height: 100, // Adjust the height as needed
    width: double.infinity,
    color: Colors.black, // Changed color to black
    child: Center(
      child: Text(
        barDatabase.getBarById(historyIds[0])?.name ?? 'No Name', // Changed text to display the name of the pinned bar
        style: const TextStyle(color: Colors.white, fontSize: 24),
      ),
    ),
  ),






















          ],
        ),
      ),
    );
  }
}
