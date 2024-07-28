import 'package:barzzy_app1/Backend/barhistory.dart';
import 'package:barzzy_app1/Backend/drink.dart';
import 'package:barzzy_app1/Backend/user.dart';
import 'package:barzzy_app1/OrdersPage/cart.dart';
import 'package:barzzy_app1/MenuPage/drinkfeed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../Backend/bar.dart';
import '../Backend/bardatabase.dart';
import 'package:flutter/services.dart';

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
  String autoCompleteTag = '';

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

  void _onSearchChanged() {
    setState(() {
      hasText = _searchController.text.isNotEmpty;
      if (hasText) {
        _updateAutoComplete(_searchController.text);
      } else {
        autoCompleteTag = '';
      }
    });
  }

  void _updateAutoComplete(String query) {
    final barDatabase = Provider.of<BarDatabase>(context, listen: false);
    final matchingTags = barDatabase._tags.values
        .where((tag) => tag.name.toLowerCase().startsWith(query.toLowerCase()))
        .toList();

    if (matchingTags.isNotEmpty) {
      autoCompleteTag = matchingTags.first.name;
    } else {
      autoCompleteTag = '';
    }
  }

  //LOADS DRINK IN

  Future<void> _fetchBarData() async {
    currentBar = BarDatabase.getBarById(widget.barId);
    if (currentBar != null) {
      appBarTitle =
          (currentBar!.tag ?? 'Menu Page').replaceAll(' ', '').toLowerCase();
    }
    setState(() {
      isLoading = false;
    });
    final barHistory = Provider.of<BarHistory>(context, listen: false);
    barHistory.setTappedBarId(widget.barId);
  }

  void _search(String query) {
    if (query.trim().isEmpty) {
      // If query contains only empty spaces or is empty after trimming, do nothing
      return;
    }
    final user = Provider.of<User>(context, listen: false);
    final barDatabase = Provider.of<BarDatabase>(context, listen: false);
    barDatabase.searchDrinks(query, user, widget.barId);
    setState(() {
      FocusScope.of(context).unfocus(); // Close keyboard
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => Cart(),
      child: SafeArea(
        child: GestureDetector(
          onHorizontalDragUpdate: (details) {
            // Handle horizontal drag update here
            if (details.primaryDelta! > 0) {
              // Swiping to the right
            }
          },
          child: Scaffold(
              backgroundColor: Colors.black,
              body: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(children: [
                      SizedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            //BACK ARROW BUTTON

                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.grey,
                                size: 29,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),

                            // BAR NAME

                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 5),
                                child: Text(
                                  appBarTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                            ),

                            // MENU BUTTON

                            Consumer<Cart>(
                              builder: (context, cart, _) {
                                bool hasItemsInCart =
                                    cart.getTotalDrinkCount() > 0;
                                return IconButton(
                                  onPressed: () {},
                                  icon: Icon(
                                    FontAwesomeIcons.penToSquare,
                                    size: 21.25,
                                    color: hasItemsInCart
                                        ? Colors.white
                                        : Colors.grey,
                                  ), // Replace with your desired icon
                                );
                              },
                            )
                          ],
                        ),
                      ),

                      Expanded(
                        child: SingleChildScrollView(
                            reverse: true,
                            key: _listKey,
                            controller: _scrollController,
                            child: Consumer<User>(builder: (context, user, _) {
                              final queryHistoryEntries =
                                  user.getQueryHistory(widget.barId);

                              return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: queryHistoryEntries.length,
                                  itemBuilder: (context, index) {
                                    return Column(
                                      children: [
                                        Consumer<User>(
                                            builder: (context, user, _) {
                                          final query =
                                              queryHistoryEntries[index];
                                          return Row(
                                            mainAxisAlignment: MainAxisAlignment
                                                .end, // Align text to the right
                                            children: [
                                              const SizedBox(width: 50),
                                              Flexible(
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 10,
                                                      horizontal: 15),
                                                  margin: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 2.5,
                                                      horizontal: 0),
                                                  child: Text(
                                                    '`$query',
                                                    style: const TextStyle(
                                                      fontSize: 15.0,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }),

                                        //DRINK RESULTS AND RESPONSE
                                        Consumer<User>(
                                          builder: (context, user, _) {
                                            // final searchHistoryEntries = user.getSearchHistory(widget.barId) ?? [];
                                            // final responseHistory = user.getResponseHistory(widget.barId) ?? [];
                                            final searchHistoryEntries = user
                                                .getSearchHistory(widget.barId);
                                            final responseHistory =
                                                user.getResponseHistory(
                                                    widget.barId);
                                            final entry = index <
                                                    searchHistoryEntries.length
                                                ? searchHistoryEntries[index]
                                                : null;
                                            final drinkIds = entry?.value ?? [];
                                            final response =
                                                index < responseHistory.length
                                                    ? responseHistory[index]
                                                    : '';

                                            if (entry == null) {
                                              return const Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(width: 17.5),
                                                  SpinKitThreeBounce(
                                                    color: Colors.white,
                                                    size: 22.5,
                                                  ),
                                                ],
                                              ); // or a loading indicator
                                            }

                                            return Column(
                                              children: [
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
                                                        const QuiltedGridTile(
                                                            2, 1),
                                                        const QuiltedGridTile(
                                                            2, 1),
                                                        const QuiltedGridTile(
                                                            2, 1),
                                                      ]),
                                                  childrenDelegate:
                                                      SliverChildBuilderDelegate(
                                                    (context, index) {
                                                      final barDatabase =
                                                          Provider.of<
                                                                  BarDatabase>(
                                                              context,
                                                              listen: false);
                                                      final drink = barDatabase
                                                          .getDrinkById(
                                                              drinkIds[index]);

                                                      // DRINK FEED

                                                      return GestureDetector(
                                                        onLongPress: () {
                                                          HapticFeedback
                                                              .heavyImpact();

                                                          final cart =
                                                              Provider.of<Cart>(
                                                                  context,
                                                                  listen:
                                                                      false);
                                                          Navigator.of(context)
                                                              .push(
                                                                  _createRoute(
                                                            drink,
                                                            cart,
                                                          ));
                                                        },
                                                        onDoubleTap: () {
                                                          HapticFeedback
                                                              .lightImpact();
                                                          Provider.of<Cart>(
                                                                  context,
                                                                  listen: false)
                                                              .addDrink(
                                                                  widget.barId,
                                                                  drink.id);
                                                        },
                                                        child: ClipRRect(
                                                          child: Stack(
                                                            children: [
                                                              Positioned.fill(
                                                                child: Image
                                                                    .network(
                                                                  drink.image,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                ),
                                                              ),
                                                              Positioned.fill(
                                                                child: Consumer<
                                                                    Cart>(
                                                                  builder:
                                                                      (context,
                                                                          cart,
                                                                          _) {
                                                                    int drinkQuantities = cart.getDrinkQuantity(
                                                                        widget
                                                                            .barId,
                                                                        drink
                                                                            .id);

                                                                    // Only render the container if drinkQuantities is greater than 0
                                                                    if (drinkQuantities >
                                                                        0) {
                                                                      return Container(
                                                                        decoration:
                                                                            const BoxDecoration(
                                                                          color:
                                                                              Colors.black54,
                                                                          // borderRadius:
                                                                          //     BorderRadius.circular(12),
                                                                        ),
                                                                        child:
                                                                            Center(
                                                                          child:
                                                                              Text(
                                                                            'x$drinkQuantities',
                                                                            style:
                                                                                const TextStyle(
                                                                              color: Colors.white54,
                                                                              fontSize: 40,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      );
                                                                    } else {
                                                                      return const SizedBox
                                                                          .shrink(); // Render an empty widget if drinkQuantities is 0
                                                                    }
                                                                  },
                                                                ),
                                                              ),
                                                              Positioned.fill(
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    const SizedBox(
                                                                        height:
                                                                            10),
                                                                    Row(
                                                                      children: [
                                                                        Expanded(
                                                                          child:
                                                                              Text(
                                                                            '`${drink.name}',
                                                                            style: const TextStyle(
                                                                                fontSize: 13,
                                                                                fontWeight: FontWeight.w600,
                                                                                fontStyle: FontStyle.italic,
                                                                                color: Colors.white),
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            maxLines:
                                                                                1,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                15)
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    childCount:
                                                        drinkIds.length > 6
                                                            ? 6
                                                            : drinkIds.length,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 10,
                                                                horizontal: 15),
                                                        margin: const EdgeInsets
                                                            .symmetric(
                                                            vertical: 2.5,
                                                            horizontal: 0),
                                                        child: Text(
                                                          response,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 15.0,
                                                            fontStyle: FontStyle
                                                                .italic,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 50),
                                                  ],
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    );
                                  });
                            })),
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
                                        labelText: 'Find Your Drink...',
                                        labelStyle: const TextStyle(
                                          color: Colors
                                              .white, // Set the color of the label text here
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                              color: Colors.grey),
                                          borderRadius:
                                              BorderRadius.circular(20.0),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20.0),
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
                                                      BorderRadius.circular(
                                                          20)),
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
                                  // onTap: () {
                                  //   if (hasText) {
                                  //     String query = _searchController.text;
                                  //     debugPrint('Query being sent: $query');
                                  //     _search(query);
                                  //     _searchController.clear();

                                  //     // Send message functionality
                                  //   }
                                  // },
                                  onTap: () {
                                    if (hasText) {
                                      String query = autoCompleteTag.isNotEmpty
                                          ? autoCompleteTag
                                          : _searchController.text;
                                      debugPrint('Query being sent: $query');
                                      _search(query);
                                      _searchController.clear();
                                    }
                                  })
                            ],
                          ),
                        ),
                      ),
                    ])),
        ),
      ),
    );
  }

//EXPANDED IMAGE

  Route _createRoute(Drink drink, Cart cart) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => DrinkFeed(
        drink: drink,
        cart: cart,
        barId: widget.barId,
      ),
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

  void _scrollToBottom() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
    );
  }
}
