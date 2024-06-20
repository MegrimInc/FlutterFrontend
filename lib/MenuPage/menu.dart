import 'package:barzzy_app1/Backend/barhistory.dart';
import 'package:barzzy_app1/Backend/drink.dart';
import 'package:barzzy_app1/Backend/user.dart';
import 'package:barzzy_app1/MenuPage/chatbot.dart';
import 'package:barzzy_app1/MenuPage/drinkfeed.dart';
import 'package:barzzy_app1/MenuPage/infinitescroll.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import '../Backend/bar.dart';
import '../Backend/bardatabase.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

class MenuPage extends StatefulWidget {
  final String barId;

  const MenuPage({
    super.key,
    required this.barId,
  });

  @override
  MenuPageState createState() => MenuPageState();
}

class MenuPageState extends State<MenuPage> {
  String appBarTitle = '';
  bool isLoading = true;
  Bar? currentBar;
  final TextEditingController _searchController = TextEditingController();
  bool hasText = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _fetchBarData();
    _searchController.addListener(() {
      setState(() {
        hasText = _searchController.text.isNotEmpty;
      });
    });
  }

  //LOADS DRINK IN

  Future<void> _fetchBarData() async {
    currentBar = BarDatabase.getBarById(widget.barId);
    if (currentBar != null) {
      appBarTitle =
          (currentBar!.tag ?? 'Menu Page').replaceAll(' ', '').toLowerCase();
      // debugPrint('nameAndTagMap contents: ${currentBar!.getNameAndTagMap()}');
    }
    setState(() {
      isLoading = false;
    });
    await _handleBarTapAndReorder();
  }

  void _search(String query) {
    if (query.trim().isEmpty) {
      // If query contains only empty spaces or is empty after trimming, do nothing
      return;
    }

    final user = Provider.of<User>(context, listen: false);
    currentBar?.searchDrinks(query, user, widget.barId);
    setState(() {
      FocusScope.of(context).unfocus(); // Close keyboard
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Colors.black,
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(children: [
                  Expanded(
                    child: SingleChildScrollView(
                      reverse: true,
                      key: _listKey,
                      controller: _scrollController,
                      child: Column(
                        children: [
                          Consumer<User>(
                            builder: (context, user, _) {
                              final searchHistoryEntries =
                                  user.getSearchHistory(widget.barId);

                              return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: searchHistoryEntries.length,
                                  itemBuilder: (context, index) {
                                    final entry = searchHistoryEntries[index];
                                    final query = entry.key;
                                    final drinkIds = entry.value;
                                    return Column(
                                      children: [
                                        ListTile(
                                          title: Text(
                                            query,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),

                                        // List of Search Results
                                        GridView.custom(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          gridDelegate:
                                              SliverQuiltedGridDelegate(
                                            crossAxisCount: 3,
                                            mainAxisSpacing: 2.5,
                                            crossAxisSpacing: 2.5,
                                            pattern: _generatePattern(
                                                drinkIds.length),
                                          ),
                                          childrenDelegate:
                                              SliverChildBuilderDelegate(
                                            (context, index) {
                                              final drink = currentBar!.drinks!
                                                  .firstWhere((d) =>
                                                      d.id == drinkIds[index]);

                                              // DRINK FEED

                                              return GestureDetector(
                                                onLongPress: () {
                                                  // Trigger haptic feedback on long press
                                                  HapticFeedback.heavyImpact();
                                                  Future.delayed(
                                                      const Duration(
                                                          milliseconds: 150),
                                                      () {
                                                    Navigator.of(context).push(
                                                        _createRoute(drink));
                                                  });
                                                },
                                                child: ClipRRect(
                                                  borderRadius:
                                                      const BorderRadius
                                                          .vertical(),
                                                  child: Stack(
                                                    children: [
                                                      Positioned.fill(
                                                        child: Image.asset(
                                                          drink.image,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                      Positioned.fill(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.baseline,
                                                        children: [
                                                          Infinitescroll(
                                                              childrenWidth:
                                                                  _calculateTextWidth(
                                                                "${drink.name}: ${drink.ingredients.join(' ')} ${drink.name}: '${drink.ingredients.join(' ')}"),
                                                              scrollDuration:
                                                                  const Duration(
                                                                      seconds:
                                                                          60),
                                                              children: [
                                                                Text(
                                                                  "${drink.name}: ${drink.ingredients.join(' ')} ${drink.name}: '${drink.ingredients.join(' ')}",
                                                                  style:
                                                                      const TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight.bold,
                                                                  ),
                                                                ),
                                                              ]),
                                                        ],
                                                      ))
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                            childCount: drinkIds.length > 6
                                                ? 6
                                                : drinkIds.length,
                                          ),
                                        ),
                                      ],
                                    );
                                  });
                            },
                          ),
                          const SizedBox(
                            height: 25,
                          )
                        ],
                      ),
                    ),
                  ),

                  // BOTTOM BAR
                  SizedBox(
                    height: 60,
                    child: BottomAppBar(
                      color: Colors.black,

                      //BACK ICON
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: .5),
                            child: GestureDetector(
                              child: Row(
                                children: [
                                  Container(
                                      height: 30,
                                      width: 30,
                                      decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                              255, 52, 51, 51),
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.grey,
                                        size: 22,
                                      )),
                                  const SizedBox(width: 20),
                                ],
                              ),
                              onTap: () {},
                            ),
                          ),

                          //MESSAGE FIELD
                          Expanded(
                            child: SizedBox(
                              height: 35,
                              child: TextFormField(
                                cursorColor: Colors.white,
                                controller: _searchController,
                                onTap: () {
                                  _scrollToBottom(); // Trigger scroll to bottom when text field is tapped
                                },
                                decoration: InputDecoration(
                                    labelText: 'Message..',
                                    labelStyle: const TextStyle(
                                      color: Colors
                                          .white, // Set the color of the label text here
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide:
                                          const BorderSide(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                      borderSide: const BorderSide(
                                        color: Colors.grey,
                                      ), // Same color as default
                                    ),
                                    contentPadding: const EdgeInsets.only(
                                        left: 15.0, bottom: 0),
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.never),
                              ),
                            ),
                          ),

                          //QR AND SEARCH BUTTON
                          GestureDetector(
                            child: Row(
                              children: [
                                const SizedBox(width: 20),
                                hasText
                                    ? Container(
                                        height: 27,
                                        width: 27,
                                        decoration: BoxDecoration(
                                            color: const Color.fromARGB(
                                                255, 255, 255, 255),
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        child: const Icon(
                                          Icons.arrow_upward_outlined,
                                          size: 19,
                                          color: Colors.black,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.qr_code_scanner_rounded,
                                        size: 25,
                                        color: Colors.grey,
                                      ),
                              ],
                            ),
                            onTap: () {
                              if (hasText) {
                                String query = _searchController.text;
                                debugPrint('Query being sent: $query');
                                _search(query);
                                _searchController.clear();

                                // Send message functionality
                              } else {}
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                ])),
    );
  }

  // PATTERN METHOD

  List<QuiltedGridTile> _generatePattern(int length) {
    List<QuiltedGridTile> pattern = [];
    pattern.addAll([
      const QuiltedGridTile(2, 1),
      const QuiltedGridTile(2, 1),
      const QuiltedGridTile(2, 1),
    ]); // Add the initial pattern for index 0
    for (int i = 1; i < length; i++) {
      pattern.addAll([
        const QuiltedGridTile(2, 1),
        const QuiltedGridTile(2, 1),
        const QuiltedGridTile(2, 1),
      ]);
    }
    return pattern;
  }

//SENDS ID TO BAR HISTORY CLASS

  Future<void> _handleBarTapAndReorder() async {
    await Future.delayed(Duration.zero);
    // ignore: use_build_context_synchronously
    final barHistory = Provider.of<BarHistory>(context, listen: false);
    // ignore: use_build_context_synchronously
    barHistory.tapBar(widget.barId, context);

    barHistory.reorderList(widget.barId);
  }
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  
  
  Route _createRoute(Drink drink) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          DrinkFeed(drink: drink),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = 0.0;
        var end = 1.0;
        var curve = Curves.easeInOut;

        var scaleTween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var fadeTween =
            Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

        return ScaleTransition(
          scale: animation.drive(scaleTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
    );
  }





double _calculateTextWidth(String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: double.infinity);
    // Return the text width with additional padding or margin as needed
    return textPainter.width + 16; // Adjust this padding/margin as per your layout needs
  }






}
