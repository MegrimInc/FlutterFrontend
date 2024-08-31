// ignore_for_file: use_build_context_synchronously

import 'package:barzzy_app1/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy_app1/Backend/barhistory.dart';
import 'package:barzzy_app1/Backend/drink.dart';
import 'package:barzzy_app1/Backend/user.dart';

import 'package:barzzy_app1/MenuPage/cart.dart';
import 'package:barzzy_app1/MenuPage/drinkfeed.dart';
import 'package:barzzy_app1/OrdersPage/hierarchy.dart';
import 'package:barzzy_app1/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../Backend/bar.dart';
import '../Backend/localdatabase.dart';
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

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _fetchBarData();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  //LOADS DRINK IN

  Future<void> _fetchBarData() async {
    currentBar = LocalDatabase.getBarById(widget.barId);
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

  void _submitOrder(BuildContext context) async {
    final loginCache = Provider.of<LoginCache>(context, listen: false);
    final userId = await loginCache.getUID();
    final cart = Provider.of<Cart>(context, listen: false);
    final hierarchy = Provider.of<Hierarchy>(context, listen: false);

    final barId = widget.barId;

    // Create the drink quantities list
    final drinkQuantities = cart.barCart.entries.map((entry) {
      return {
        'drinkId': int.parse(entry.key),
        'quantity': entry.value,
      };
    }).toList();

    // Construct the order object
    final order = {
      "action": "create",
      "barId": barId,
      "userId": userId,
      "drinks": drinkQuantities,
    };

    // Pass the order object to the createOrder method
    hierarchy.createOrder(order);

    // Navigate to orders page or perform other actions as needed
    navigateToOrdersPage(context);
  }

  // Method to refresh the drink list for the current bar
  Future<void> _refreshDrinks() async {
    print('hey are you working');
    final user = Provider.of<User>(context, listen: false);
    user.clearHistoriesForBar(
        widget.barId); // Clear the user's data for this bar
    await fetchTagsAndDrinks(widget.barId); // Fetch the drinks for this bar
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
                        onHorizontalDragEnd: (details) {
                          if (details.velocity.pixelsPerSecond.dx < -50) {
                            // Swiping left from the right edge
                            // Start the order submission process
                            _submitOrder(context);
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

            // REFRESH BUTTON

            IconButton(
              onPressed: () {
                print('plz baby girl');
                _refreshDrinks();
              },
              icon: const FaIcon(
                FontAwesomeIcons.arrowsRotate,
                size: 22,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),

      Expanded(
        child: SingleChildScrollView(
            //reverse: true,
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
                                    query,
                                    style: GoogleFonts.poppins(
                                        fontSize: 15.5,
                                        //fontWeight:
                                        // FontWeight.bold,
                                        color: Colors.white,
                                        fontStyle: FontStyle.italic),
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

                            final entry = index < searchHistoryEntries.length
                                ? searchHistoryEntries[index]
                                : null;
                            final drinkIds = entry?.value ?? [];

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
                                          Provider.of<LocalDatabase>(context,
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
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontStyle:
                                                                  FontStyle
                                                                      .italic,
                                                              color: Colors
                                                                  .white54,
                                                            ),
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
                                const SizedBox(height: 30)
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
      Container(
        height: 67,
        child: const BottomAppBar(
          color: Colors.black,

          //PLUS ICON
          child: Row(
            children: [],
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
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/orders', (Route<dynamic> route) => false);
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
    _searchController.dispose();
    super.dispose();
  }
}
