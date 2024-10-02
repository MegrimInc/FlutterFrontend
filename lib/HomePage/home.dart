import 'package:barzzy/HomePage/bottomsheet.dart';
import 'package:barzzy/HomePage/hometopicons.dart';
import 'package:barzzy/OrdersPage/hierarchy.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/heroicons_solid.dart';
import 'package:provider/provider.dart';
import 'package:barzzy/Backend/barhistory.dart';
import 'package:barzzy/Backend/recommended.dart';
import 'package:barzzy/MenuPage/menu.dart';
import '../Backend/localdatabase.dart';

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
    _connect();
    _updateMasterList();
  }

  Future<void> _connect() async {
    final hierarchy = Provider.of<Hierarchy>(context, listen: false);
    hierarchy.connect(context); // No need to await since it returns void
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 8.29),
              child: const MyTopIcons(),
            ),

            //MASTER LIST

            Consumer<Recommended>(
              builder: (context, recommended, _) {
                final recommendedIds = recommended.barIds;
                masterList = [...recommendedIds].take(4).toList();

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
                        //final isTapped = barHistory.barIds.contains(barId);
                        final isRecommended = recommendedIds.contains(barId);
                        final bar = LocalDatabase.getBarById(barId);
                        return GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MenuPage(barId: barId),
                                ),
                              );
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
                                      borderRadius: BorderRadius.circular(60),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(60),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          // Always display the image
                                          CachedNetworkImage(
                                            imageUrl: bar?.tagimg ??
                                                'https://www.barzzy.site/images/default.png',
                                            fit: BoxFit.cover,
                                          ),

                                          // Conditionally display the icon over the image
                                          if (isRecommended)
                                            const Padding(
                                                padding: EdgeInsets.all(20),
                                                child: Padding(
                                                  padding: EdgeInsets.fromLTRB(
                                                      20, 8, 0, 2),
                                                  child: Iconify(
                                                    HeroiconsSolid.search,
                                                    color: Colors.white,
                                                  ),
                                                )),
                                        ],
                                      ),
                                    ),
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

            if (barHistory.currentTappedBarId != null)
              SizedBox(
                height: 65.5,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 17),
                        child: Text(
                          LocalDatabase.getBarById(
                                      barHistory.currentTappedBarId!)
                                  ?.name ??
                              'No Name',
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: IconButton(
                            icon: const Icon(Icons.history_rounded,
                                size: 28, color: Colors.grey),
                            onPressed: () {
                              showBottomSheet(
                                  context, barHistory.currentTappedBarId!);
                            }),
                      ),
                    ]),
              ),

            // MAIN MOST RECENT BAR

            if (barHistory.currentTappedBarId != null)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MenuPage(
                      barId: barHistory.currentTappedBarId!,
                    ),
                  ),
                ),
                child: Container(
                  height: 401,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                  ),
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: LocalDatabase.getBarById(
                            barHistory.currentTappedBarId!,
                          )?.barimg ??
                          'https://www.barzzy.site/images/champs/6.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

            //BOTTOM ROW WITH RECENT DRINKS AND WAIT TIME

            if (barHistory.currentTappedBarId != null)
              GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.velocity.pixelsPerSecond.dy < -50) {
                    showBottomSheet(context, barHistory.currentTappedBarId!);
                  }
                },
                child: Container(
                  decoration: const BoxDecoration(),
                  height: 65.5,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 17),
                        child: Text(
                          LocalDatabase.getBarById(
                                      barHistory.currentTappedBarId!)
                                  ?.openhours ??
                              'No Hours Available',
                          style: const TextStyle(
                            color: Colors.white,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(right: 17),
                        child: Text(
                          'Floor: 1 / 1',
                          style: TextStyle(
                            color: Colors.white,
                            //fontWeight: FontWeight.bold
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
