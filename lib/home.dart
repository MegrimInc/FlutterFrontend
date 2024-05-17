
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
           
           
           // BARZZY LOGO, SEARCH, AND TAB
            
              //DEFAULT
            if (historyLength == 0)
            Container(
              decoration: const BoxDecoration(
              border: Border(
              bottom: BorderSide(color: Color.fromARGB(255, 126, 126, 126), width: 0.0425),
              ),
            ),
            padding: const EdgeInsets.only(bottom: 8.29),
              child: const MyTopIcons(),
            ),







              if (historyLength == 0)
              
              
              const Padding(
                padding: EdgeInsets.only(top: 300),
                child: Center(child: Text('FIND YOUR BAR')),
              ),






              //CONTENT
              if (historyLength > 0)
            Container(
            padding: const EdgeInsets.only(bottom: 8),
              child: const MyTopIcons(),
            ),


            
            // RECENT BARS LIST
              // CONTENT

             if (historyLength > 1)
  Padding(
    padding: const EdgeInsets.only(
      left: 5,
    ),
    child: Container(
      padding: const EdgeInsets.only(bottom: 12),
      height: 130, // Adjusted height to fit the name below
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
                  child: const Text('')
                ),
                const SizedBox(height: 2.9),
                Text(
                  barDatabase.getBarById(historyIds[index + 1])?.name ?? 'No Name',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        },
      ),
    ),
  ),   
              
              

            // DEFAULT


              if (historyLength == 1)
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Container(
                  padding: const EdgeInsets.only(bottom: 12),
                  height: 130,
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
                          const Text(
                            'Recents',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    //   const SizedBox(width: 45),

                    //    Text( 
                    //     'No Recents', 
                    //   style: GoogleFonts.sourceSans3(
                    //   fontSize: 15,
                    //   color: Colors.white,
                    // ),)
                    ],
                  ),
                ),
              ),




















              
              
              
              
              
              
              const SizedBox(height: 17.5),














            

             // TOP ROW WITH BAR NAME AND WAIT TIME 
            
                  if (historyLength > 0)
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:[

                    
                    Text(
                      barDatabase.getBarById(historyIds[0])?.name ?? 'No Name',
                      style: const TextStyle(color: Colors.white),
                      ),



                    Text(
        'Wait: 10 min',
        style: GoogleFonts.sourceSans3(
          fontSize: 15,
          color: Colors.white,
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
                    //border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(
                    child: Text(
                      'Picture',
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 24),
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
      RichText(
  text: const TextSpan(
    children: [
      TextSpan(
        text: 'Open',
        style: TextStyle(
          //fontWeight: FontWeight.w900,
          fontSize: 15,
          color: Colors.green,
        ),
      ),
      TextSpan(
        text: ' / ',
        style: TextStyle(
          //fontWeight: FontWeight.w900,
          fontSize: 17.5,
          color: Colors.white,
        ),
      ),
      TextSpan(
        text: 'Closed',
        style: TextStyle(
          //fontWeight: FontWeight.w900,
          fontSize: 15,
          color: Colors.grey,
        ),
      ),
    ],
  ),
),


      GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.black,
            builder: (BuildContext context) {
              double screenHeight = MediaQuery.of(context).size.height;
              double bottomSheetHeight = screenHeight * 0.718;

              return Container(
                height: bottomSheetHeight,
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                   borderRadius: BorderRadius.circular(20),
                  border: const Border(
                    top: BorderSide(
                      color: Color.fromARGB(255, 126, 126, 126),
                      width: 0.1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 150,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    // Add more widgets as needed
                  ],
                ),
              );
            },
          );
        },
        child: const Icon(
    Icons.history_rounded, // or Icons.bookmark_border, or Icons.bookmark_outline
    color: Colors.grey,
    size: 27.5,
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