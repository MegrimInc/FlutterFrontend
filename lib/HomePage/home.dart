import 'dart:convert';

import 'package:barzzy/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy/MenuPage/cart.dart';
import 'package:barzzy/OrdersPage/websocket.dart';
import 'package:barzzy/SearchPage/searchpage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/heroicons_solid.dart';
import 'package:provider/provider.dart';
import 'package:barzzy/Backend/barhistory.dart';
import 'package:barzzy/Backend/recommended.dart';
import 'package:barzzy/MenuPage/menu.dart';
import '../Backend/localdatabase.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List<String> masterList = [];
  List<String> tappedIds = [];
  late double screenHeight;
  late double bottomHeight;
  late double paddingHeight;

  @override
  void initState() {
    super.initState();
    _connect();
    _updateMasterList();
    checkPaymentMethod();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Dynamically calculate the available screen height
    screenHeight = MediaQuery.of(context).size.height -
        (3.8 * kToolbarHeight); // Subtract twice the AppBar height
    bottomHeight = (MediaQuery.of(context).size.height - screenHeight) * .5;
    paddingHeight = bottomHeight * .18;
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

  Future<void> checkPaymentMethod() async {
    LocalDatabase localDatabase = LocalDatabase();
    LoginCache loginCache = LoginCache();
    final userId = await loginCache.getUID();

    if (userId == 0) {
      debugPrint('User ID is 0, skipping GET request for payment method.');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://www.barzzy.site/customer/checkPaymentMethod/$userId'),
      );

      if (response.statusCode == 200) {
        final paymentPresent = jsonDecode(response.body); // true or false
        debugPrint('Payment method check result: $paymentPresent');
        localDatabase.updatePaymentStatus(paymentPresent);
      } else {
        debugPrint(
            'Failed to check payment method. Status code: ${response.statusCode}');
        localDatabase.updatePaymentStatus(false);
      }
    } catch (e) {
      debugPrint('Error checking payment method: $e');
      localDatabase.updatePaymentStatus(false);
    }
  }

  Future<void> _handleRefresh() async {
    debugPrint("Refreshing HomePage...");
  }

  @override
  Widget build(BuildContext context) {
    final barHistory = Provider.of<BarHistory>(context);

    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.black,
        appBar: AppBar(
            backgroundColor: Colors.black,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
            elevation: 2,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                //BARZZY TAG

                Text(
                  'B A R Z Z Y',
                  style: GoogleFonts.megrim(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontSize: 25,
                  ),
                ),

                const SizedBox(width: 20),

                //SEARCH

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchPage(),
                      ),
                    );
                  },
                  child: const Iconify(
                    HeroiconsSolid.search,
                    size: 25,
                    color: Colors.grey,
                  ),
                ),
              ],
            )),
        body: FutureBuilder<int>(
          future: Provider.of<LoginCache>(context, listen: false).getUID(),
          builder: (context, snapshot) {
            bool isGuest = snapshot.hasData && snapshot.data == 0;
            return RefreshIndicator(
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                physics: isGuest
                    ? const NeverScrollableScrollPhysics()
                    : const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: screenHeight,
                  padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                  child: Column(
                    children: [
                      //MASTER LIST

                      Consumer<Recommended>(
                        builder: (context, recommended, _) {
                          final recommendedIds = recommended.barIds;
                          masterList = [...recommendedIds].take(4).toList();

                          return Container(
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
                                final isRecommended =
                                    recommendedIds.contains(barId);
                                final bar = LocalDatabase.getBarById(barId);
                                return GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onLongPress: () {
                                      HapticFeedback.heavyImpact();
                                      final barHistory =
                                          Provider.of<BarHistory>(context,
                                              listen: false);
                                      barHistory.setTappedBarId(barId);
                                    },
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(
                                        builder: (context) {
                                          Cart cart = Cart();
                                          cart.setBar(
                                              barId); // Set the bar ID for the cart
                                          return MenuPage(
                                            barId: barId,
                                            cart: cart,
                                          );
                                        },
                                      ));
                                    },
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 85,
                                            height: 85,
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 6),
                                            decoration: BoxDecoration(
                                              color: const Color.fromARGB(
                                                  255, 0, 0, 0),
                                              borderRadius:
                                                  BorderRadius.circular(60),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(60),
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
                                                        padding:
                                                            EdgeInsets.all(20),
                                                        child: Padding(
                                                          padding: EdgeInsets
                                                              .fromLTRB(
                                                                  20, 8, 0, 2),
                                                          child: Iconify(
                                                            HeroiconsSolid
                                                                .search,
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
                          );
                        },
                      ),

                      // EVERYTHING BELOW THE MASTER LIST

                      // TOP ROW WITH BAR NAME AND WAIT TIME

                      if (barHistory.currentTappedBarId != null)
                        Flexible(
                          flex: 2,
                          child: Column(
                            children: [
                              const Spacer(),
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 11),
                                      child: Text(
                                        LocalDatabase.getBarById(barHistory
                                                    .currentTappedBarId!)
                                                ?.name ??
                                            'No Name',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                        icon: const Icon(Icons.more_horiz,
                                            size: 24, color: Colors.grey),
                                        onPressed: () {}),
                                  ]),
                              const Spacer(),
                            ],
                          ),
                        ),

                      // MAIN MOST RECENT BAR

                      if (barHistory.currentTappedBarId != null)
                        Expanded(
                          flex: 15,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    // Create a new Cart instance and initialize it
                                    Cart cart = Cart();
                                    cart.setBar(barHistory
                                        .currentTappedBarId!); // Set the bar ID for the cart

                                    // Pass the newly created Cart instance to the MenuPage
                                    return MenuPage(
                                      barId: barHistory.currentTappedBarId!,
                                      cart: cart,
                                    );
                                  },
                                ),
                              );
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black,
                              ),
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
                        Flexible(
                          flex: 2,
                          child: Column(
                            children: [
                              const Spacer(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 11),
                                    child: RichText(
                                      text: const TextSpan(
                                        children: [
                                          TextSpan(
                                            text: "Open",
                                            style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14),
                                          ),
                                          TextSpan(
                                            text: " / ",
                                            style: TextStyle(
                                                color: Colors.grey,
                                                //fontWeight: FontWeight.bold,
                                                fontSize: 14),
                                          ),
                                          TextSpan(
                                            text: "Closed",
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 11),
                                    child: Text(
                                      LocalDatabase.getBarById(barHistory
                                                  .currentTappedBarId!)
                                              ?.address ??
                                          'No Address Available',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        //fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: FutureBuilder<int>(
          future: Provider.of<LoginCache>(context, listen: false).getUID(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink(); // Return nothing while waiting
            }
            if (snapshot.hasData && snapshot.data == 0) {
              return Container(
                height: bottomHeight,
                width: double.infinity, // Ensures full-width alignment
                decoration: const BoxDecoration(
                  color: Colors.black, // Background color for better visibility
                  border: Border(
                    top: BorderSide(
                      color: Color.fromARGB(255, 126, 126, 126),
                      width: 0.1,
                    ),
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: paddingHeight),
                    child: const Text(
                      '⚠️   WARNING: VIEW ONLY   ⚠️',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink(); // Return nothing if userId is not 0
          },
        ));
  }
}
