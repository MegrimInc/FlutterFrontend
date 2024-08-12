// ignore_for_file: use_build_context_synchronously

import 'package:barzzy_app1/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy_app1/Backend/barhistory.dart';
import 'package:barzzy_app1/Backend/drink.dart';
import 'package:barzzy_app1/Backend/user.dart';
import 'package:barzzy_app1/MenuPage/overlay.dart';
import 'package:barzzy_app1/MenuPage/cart.dart';
import 'package:barzzy_app1/MenuPage/drinkfeed.dart';
import 'package:barzzy_app1/OrdersPage/hierarchy.dart';
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

class MenuPageState extends State<MenuPage>
    with SingleTickerProviderStateMixin {
  String appBarTitle = '';
  bool isLoading = true;
  Bar? currentBar;
  final TextEditingController _searchController = TextEditingController();
  bool hasText = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  String autoCompleteTag = '';
  bool _showOverlay = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _fetchBarData();
    _searchController.addListener(_onSearchChanged);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  void _onSearchChanged() {
    setState(() {
      hasText = _searchController.text.isNotEmpty;
      _updateAutoComplete(_searchController.text);
    });
  }

  void _updateAutoComplete(String query) {
    final barDatabase = Provider.of<BarDatabase>(context, listen: false);
    final matchingTags = barDatabase.tags.values
        .where((tag) => tag.name.toLowerCase().startsWith(query.toLowerCase()))
        .toList();

    if (matchingTags.isNotEmpty) {
      autoCompleteTag = matchingTags.first.name;
    } else {
      autoCompleteTag = query; // Display the user's input if no matching tag
    }
  }

  //LOADS DRINK IN

  Future<void> _fetchBarData() async {
    currentBar = BarDatabase.getBarById(widget.barId);
    if (currentBar != null) {
      appBarTitle = ('*${currentBar!.tag ?? 'Menu Page'}')
          .replaceAll(' ', '')
          .toLowerCase();
      //appBarTitle = ('*${currentBar!.tag ?? 'Menu Page'}');
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

  void _showOverlayWidget() {
    setState(() {
      _showOverlay = true;
    });
    _animationController.forward();
  }

  void _hideOverlayWidget() {
    _animationController.reverse().then((_) {
      setState(() {
        _showOverlay = false;
      });
    });
  }

  void _placeOrder(BuildContext context) async {
  final loginCache = Provider.of<LoginCache>(context, listen: false);
  final userId = await loginCache.getUID();
  final barId = int.parse(widget.barId); // Convert barId to int
  final cart = Provider.of<Cart>(context, listen: false);
  final hierarchy = Provider.of<Hierarchy>(context, listen: false);

  // Convert the drink IDs in the cart to a Map<int, int> where key is drinkId and value is quantity
  final drinkQuantities = cart.barCart.map((key, value) => MapEntry(int.parse(key), value));

  // Debug print to confirm method call
  debugPrint('Calling addOrder with barId: $barId, drinkQuantities: $drinkQuantities');

  // Call the addOrder method, passing the barId, userId, and drinkQuantities
  await hierarchy.addOrder(barId, userId, drinkQuantities);

  // Optionally, show a confirmation message
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Order placed successfully!')),
  );

  // Clear the cart after placing the order (uncomment if you want to clear it)
  //cart.barCart.clear();
}

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      //create: (context) => Cart(),
      create: (context) {
        Cart cart = Cart();
        cart.setBar(widget.barId); // Set the bar ID for the cart
        return cart;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // Main content
              _buildMainContent(),

              //ORDER SWIPE

              Consumer<Cart>(
                builder: (context, cart, _) {
                  // Check if there are items in the cart
                  if (cart.getTotalDrinkCount() > 0) {
                    return Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: 12.5, // Adjust this width as needed
                      child: GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          if (details.primaryDelta! < 0) {
                            // Swiping left from the right edge
                            navigateToOrdersPage(context);
                            _placeOrder(context);
                          }
                        },
                        child: Container(
                          color: Colors.red, // Invisible swipe area
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox
                        .shrink(); // Render an empty widget if the cart is empty
                  }
                },
              ),

              // Overlay content
              if (_showOverlay)
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform(
                      transform: Matrix4.identity()
                        ..scale(_animation.value)
                        ..translate(
                          -1.0 *
                              MediaQuery.of(context).size.width /
                              2 *
                              (1 - _animation.value),
                          MediaQuery.of(context).size.height *
                              (1 - _animation.value),
                        ),
                      alignment: Alignment.bottomLeft,
                      child: FadeTransition(
                        opacity: _animation,
                        child: child,
                      ),
                    );
                  },
                  child: Consumer<Cart>(
                    builder: (context, cart, _) {
                      return HistorySheet(
                        barId: widget.barId,
                        onClose: _hideOverlayWidget,
                        cart: cart,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(children: [
      SizedBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            //BACK ARROW BUTTON

            IconButton(
              icon: const Icon(
                //Icons.arrow_back,
                //FontAwesomeIcons.arrowLeftLong,
                FontAwesomeIcons.caretLeft,
                color: Colors.white,
                size: 29,
              ),
              onPressed: () => Navigator.pop(context),
            ),

            // BAR NAME

            Center(
              child: Text(
                appBarTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),

            // MENU BUTTON

            Consumer<Cart>(
              builder: (context, cart, _) {
                bool hasItemsInCart = cart.getTotalDrinkCount() > 0;
                return IconButton(
                  onPressed: () {},
                  icon: Icon(
                    FontAwesomeIcons.forward,
                    //FontAwesomeIcons.caretRight,
                    size: 22.5,
                    color: hasItemsInCart ? Colors.white : Colors.grey,
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
              final queryHistoryEntries = user.getQueryHistory(widget.barId);

              return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: queryHistoryEntries.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        Consumer<User>(builder: (context, user, _) {
                          final query = queryHistoryEntries[index];
                          return Row(
                            mainAxisAlignment: MainAxisAlignment
                                .end, // Align text to the right
                            children: [
                              const SizedBox(width: 50),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 15),
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 2.5, horizontal: 0),
                                  child: Text(
                                    '*$query',
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      //fontWeight:
                                      // FontWeight.bold,
                                      color: Colors.white,
                                      // fontStyle:
                                      //     FontStyle.italic
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
                            final searchHistoryEntries =
                                user.getSearchHistory(widget.barId);
                            final responseHistory =
                                user.getResponseHistory(widget.barId);
                            final entry = index < searchHistoryEntries.length
                                ? searchHistoryEntries[index]
                                : null;
                            final drinkIds = entry?.value ?? [];
                            final response = index < responseHistory.length
                                ? responseHistory[index]
                                : '';

                            if (entry == null) {
                              return const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverQuiltedGridDelegate(
                                      crossAxisCount: 3,
                                      mainAxisSpacing: 2.5,
                                      crossAxisSpacing: 2.5,
                                      repeatPattern:
                                          QuiltedGridRepeatPattern.same,
                                      pattern: [
                                        const QuiltedGridTile(2, 1),
                                        const QuiltedGridTile(2, 1),
                                        const QuiltedGridTile(2, 1),
                                      ]),
                                  childrenDelegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final barDatabase =
                                          Provider.of<BarDatabase>(context,
                                              listen: false);
                                      final drink = barDatabase
                                          .getDrinkById(drinkIds[index]);

                                      // DRINK FEED

                                      return GestureDetector(
                                        onLongPress: () {
                                          HapticFeedback.heavyImpact();

                                          final cart = Provider.of<Cart>(
                                              context,
                                              listen: false);
                                          Navigator.of(context)
                                              .push(_createRoute(
                                            drink,
                                            cart,
                                          ));
                                        },
                                        onDoubleTap: () {
                                          HapticFeedback.lightImpact();
                                          Provider.of<Cart>(context,
                                                  listen: false)
                                              .addDrink(drink.id);
                                          FocusScope.of(context).unfocus();
                                        },
                                        child: ClipRRect(
                                          child: Stack(
                                            children: [
                                              Positioned.fill(
                                                child: Image.network(
                                                  drink.image,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Positioned.fill(
                                                child: Consumer<Cart>(
                                                  builder: (context, cart, _) {
                                                    int drinkQuantities =
                                                        cart.getDrinkQuantity(
                                                            drink.id);

                                                    // Only render the container if drinkQuantities is greater than 0
                                                    if (drinkQuantities > 0) {
                                                      return Container(
                                                        decoration:
                                                            const BoxDecoration(
                                                          color: Colors.black54,
                                                          // borderRadius:
                                                          //     BorderRadius.circular(12),
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            'x$drinkQuantities',
                                                            style:
                                                                const TextStyle(
                                                              color: Colors
                                                                  .white54,
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
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const SizedBox(height: 10),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            '`${drink.name}',
                                                            style: const TextStyle(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic,
                                                                color: Colors
                                                                    .white),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 1,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 15)
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
                                    childCount: drinkIds.length > 6
                                        ? 6
                                        : drinkIds.length,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 15),
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 2.5, horizontal: 0),
                                        child: Text(
                                          response,
                                          style: const TextStyle(
                                            fontSize: 15.5,
                                            fontStyle: FontStyle.italic,
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
        height: 67,
        child: BottomAppBar(
          color: Colors.black,

          //PLUS ICON
          child: Row(
            children: [
              GestureDetector(
                child: Container(
                  color: Colors.transparent,
                  width: 50,
                  height: 50,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 7,
                      bottom: 7,
                      right: 20,
                    ),
                    child: Container(
                        decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 52, 51, 51),
                            borderRadius: BorderRadius.circular(20)),
                        child: const Icon(
                          Icons.add,
                          color: Colors.grey,
                          size: 22,
                        )),
                  ),
                ),
                onTap: () {
                  _scrollToBottom();
                  _showOverlayWidget();
                  FocusScope.of(context).unfocus();
                },
              ),

              // MESSAGE FIELD
              Expanded(
                child: SizedBox(
                  height: 35,
                  child: Stack(
                    children: [
                      Consumer<Cart>(
                        builder: (context, cart, _) {
                          // Determine the label text based on the cart's state
                          String labelText;
                          if (cart.getTotalDrinkCount() > 0) {
                            double totalPrice = cart.calculateTotalPrice();
                            labelText =
                                'Your Total Is: \$${totalPrice.toStringAsFixed(2)}';
                          } else {
                            labelText = 'I want...';
                          }

                          return TextFormField(
                            cursorColor: Colors.white,
                            controller: _searchController,
                            onChanged: (text) => _onSearchChanged(),
                            onTap: () {
                              _scrollToBottom(); // Trigger scroll to bottom when text field is tapped
                            },
                            style: const TextStyle(
                                color: Colors
                                    .transparent), // Make the TextFormField text transparent
                            decoration: InputDecoration(
                              labelText: labelText,
                              labelStyle: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.grey),
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20.0),
                                borderSide:
                                    const BorderSide(color: Colors.grey),
                              ),
                              contentPadding:
                                  const EdgeInsets.only(left: 15.0, bottom: 0),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.never,
                            ),
                          );
                        },
                      ),
                      if (hasText && autoCompleteTag.isNotEmpty)
                        Positioned(
                          left: 15,
                          top: 0,
                          bottom: 0,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: _searchController.text,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 17),
                                  ),
                                  TextSpan(
                                    text: autoCompleteTag.substring(
                                        _searchController.text.length),
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 17),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              //QR AND SEARCH BUTTON
              GestureDetector(
                child: hasText
                    ? Container(
                        color: Colors.transparent,
                        height: 50,
                        width: 50,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 21.0, top: 7.5, bottom: 7.5),
                          child: Container(
                            decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                borderRadius: BorderRadius.circular(20)),
                            child: const Icon(
                              Icons.arrow_upward_outlined,
                              size: 19,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.transparent,
                        height: 50,
                        width: 50,
                        child: const Padding(
                          padding:
                              EdgeInsets.only(left: 21, top: 7.5, bottom: 7.5),
                          child: FaIcon(
                            FontAwesomeIcons.arrowsRotate,
                            size: 25.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                onTap: () {
                  if (hasText) {
                    String query = autoCompleteTag.isNotEmpty
                        ? autoCompleteTag
                        : _searchController.text;
                    debugPrint('Query being sent: $query');
                    _search(query);
                    _searchController.clear();
                    autoCompleteTag = ''; // Clear autoCompleteTag after search
                  }
                },
              )
            ],
          ),
        ),
      ),
    ]);
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

  void navigateToOrdersPage(BuildContext context) {
    Navigator.pushNamed(context, '/orders');
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
}
