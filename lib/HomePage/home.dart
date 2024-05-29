import 'package:barzzy_app1/HomePage/bottomsheet.dart';
import 'package:barzzy_app1/HomePage/hometopicons.dart';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/heroicons_solid.dart';
import 'package:provider/provider.dart';
import 'package:barzzy_app1/Backend/barhistory.dart';
import 'package:barzzy_app1/Backend/recommended.dart';
import 'package:barzzy_app1/MenuPage/menu.dart';
import '../Backend/bardatabase.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List<String> masterList = [];
  List<String> tappedIds = [];

  @override
  void initState() {
    super.initState();
    _updateMasterList();
  }

  void _updateMasterList() async {
    final recommended = Provider.of<Recommended>(context, listen: false);

    await recommended.fetchRecommendedBars(context);

    final recommendedIds = recommended.barIds;

    setState(() {
      masterList = [...tappedIds, ...recommendedIds];
    });
  }

  void showBottomSheet(
    BuildContext context,
    String barId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (BuildContext context) {
        return BarBottomSheet(
          barId: barId,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final barHistory = Provider.of<BarHistory>(context);
    // debugPrint('Master List in build: $masterList');
    // debugPrint('Bar History IDs in build: ${barHistory.barIds}');

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body:SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 8.29),
              child: const MyTopIcons(),
            ),
            
            //MASTER LIST
            
            Consumer2<BarHistory, Recommended>(
              builder: (context, barHistory, recommended, _) {
                final recommendedIds = recommended.barIds;
                masterList = [...barHistory.barIds.skip(1), ...recommendedIds]
                    .take(4)
                    .toList();
            
                //print('Master List (Builder): $masterList');
            
                return Padding(
                  padding: const EdgeInsets.only(left: 4.5),
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
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: masterList.length,
                      itemBuilder: (context, index) {
                        final barId = masterList[index];
                        final isTapped = barHistory.barIds.contains(barId);
                        final isRecommended = recommendedIds.contains(barId);
                        final bar = BarDatabase.getBarById(barId);
                        return GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              if (isRecommended) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        MenuPage(barId: barId),
                                  ),
                                );
                              } else {
                                showBottomSheet(
                                  context,
                                  barId,
                                );
                              }
                            },
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 85,
                                    height: 85,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(255, 0, 0, 0),
                                      border: Border.all(
                                        color: isTapped
                                            ? Colors.white
                                            : isRecommended
                                                ? Colors.green
                                                : Colors.transparent,
                                        width: .5,
                                      ),
                                      borderRadius: BorderRadius.circular(60),
                                    ),
                                    child: isRecommended
                                        ? const Padding(
                                            padding: EdgeInsets.fromLTRB(
                                                35, 25, 25, 25),
                                            child: Iconify(
                                              HeroiconsSolid.search,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(''),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(bar?.tag ?? 'No Tag',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ))
                                ]));
                      },
                    ),
                  ),
                );
              },
            ),
            
            // EVERYTHING BELOW THE MASTER LIST
            
            // TOP ROW WITH BAR NAME AND WAIT TIME
            
            if (barHistory.barIds.isNotEmpty)
            SizedBox(
              height: 68.5,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text(
                        BarDatabase.getBarById(barHistory.barIds.first)?.name ??
                            'No Name',
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: IconButton(
                          icon: const Icon(
                            Icons.history_rounded,
                            size: 30,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            showBottomSheet(context, barHistory.barIds.first);
                          }),
                    ),
                  ]),
            ),
            
            
            // MAIN MOST RECENT BAR
            
            if (barHistory.barIds.isNotEmpty)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MenuPage(
                    barId: barHistory.barIds.first,
                  ),
                ),
              ),
              child: Container(
                height: 387,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  // border: Border(
                  //   top: BorderSide(
                  //     color: Colors.white,
                  //     width: .1),
                  //   bottom: BorderSide(
                  //     color: Colors.white,
                  //     width: .1)
                  //   )
                ),
                child: const Center(
                  child: Text(
                    'Picture',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
              ),
            ),
            
            //BOTTOM ROW WITH RECENT DRINKS AND WAIT TIME
            
            if (barHistory.barIds.isNotEmpty)
            GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.velocity.pixelsPerSecond.dy < -50) {
                  showBottomSheet(context, barHistory.barIds.first);
                }
              },
              child: Container(
                decoration: const BoxDecoration(),
                height: 68.5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Open',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: ' / ',
                              style: TextStyle(
                                  fontSize: 17.5,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: 'Closed',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 20),
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
            ),
          ],
        ),
      ),
    );
  }
}
