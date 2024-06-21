import 'package:barzzy_app1/Backend/barhistory.dart';
import 'package:barzzy_app1/Backend/drink.dart';
import 'package:barzzy_app1/Backend/user.dart';
import 'package:barzzy_app1/MenuPage/cart.dart';
import 'package:barzzy_app1/MenuPage/chatbot.dart';
import 'package:barzzy_app1/MenuPage/drinkfeed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import '../Backend/bar.dart';
import '../Backend/bardatabase.dart';
import 'package:flutter/services.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

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
  Cart cart = Cart();

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
                              final responseHistory =
                                  user.getResponseHistory(widget.barId);
                              return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: searchHistoryEntries.length,
                                  itemBuilder: (context, index) {
                                    final entry = searchHistoryEntries[index];
                                    final query = entry.key;
                                    final drinkIds = entry.value;
                                    final response = responseHistory.length > index
                                        ? responseHistory[index]
                                        : '';
                                    return Column(
                                      children: [
                                        ListTile(
                                          title: Align(
                                            alignment: Alignment.centerRight,
                                            child: 
                                            
                                            
                                            
                                            






Center(
  child: Row(
    mainAxisAlignment: MainAxisAlignment.end, // Align text to the right
    children: [
      Flexible(
        child: Text(
          query,
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          
           
              
                
                
                textAlign: TextAlign.right,
                
              
            
            
          
        ),
      ),
    ],
  ),
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
                                                  repeatPattern:
                                                      QuiltedGridRepeatPattern
                                                          .same,
                                                  pattern: [
                                                const QuiltedGridTile(2, 1),
                                                const QuiltedGridTile(2, 1),
                                                const QuiltedGridTile(2, 1),
                                              ]),
                                          childrenDelegate:
                                              SliverChildBuilderDelegate(
                                            (context, index) {
                                              final drink = currentBar!.drinks!
                                                  .firstWhere((d) =>
                                                      d.id == drinkIds[index]);

                                              // DRINK FEED

                                              return GestureDetector(
                                                onTap: () {
                                                  cart.addDrink(drink.id);
                                                },
                                                onDoubleTap: () {
                                                  cart.removeDrink(drink.id);
                                                },
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
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
// Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                                                             children: [
//                                                               Text(drink.name,
//                                                               style: const TextStyle(
//                                                                fontSize: 15,
//                                                                 color: Colors.white
//                                                               ),
//                                                               ),
//                                                             ],
//                                                           ),

//Spacer(),
                                                          ...drink.ingredients
                                                              .map(
                                                                  (ingredient) {
                                                            return Text(
                                                              "`${ingredient.trim()}",
                                                              style:
                                                                  const TextStyle(
                                                                //color: Colors.white,
                                                                fontSize: 11,
                                                                //fontWeight: FontWeight.bold
                                                              ),
                                                            );
                                                          }),
                                                          const Spacer(),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceEvenly,
                                                            children: [
                                                              Text(
                                                                drink.name,
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        15,
                                                                    color: Colors
                                                                        .white),
                                                              ),
                                                            ],
                                                          )
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

                                        ListTile(
                                          title: Text(
                                            response,
                                            style: const TextStyle(
                                              fontSize: 14.0,
                                              fontStyle: FontStyle.italic,
                                              color: Colors.red,
                                            ),
                                            textAlign: TextAlign.left,
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

                      //PLUS ICON
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
                                    labelText: 'Message...',
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
                                Container(
                                  width: 20,
                                  decoration: const BoxDecoration(),
                                ),
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

//SENDS ID TO BAR HISTORY CLASS

  Future<void> _handleBarTapAndReorder() async {
    await Future.delayed(Duration.zero);
    // ignore: use_build_context_synchronously
    final barHistory = Provider.of<BarHistory>(context, listen: false);
    // ignore: use_build_context_synchronously
    barHistory.tapBar(widget.barId, context);

    barHistory.reorderList(widget.barId);
  }

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
}

