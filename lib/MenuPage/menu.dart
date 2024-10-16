// ignore_for_file: use_build_context_synchronously

import 'dart:ui';

import 'package:another_flushbar/flushbar.dart';
import 'package:barzzy/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy/AuthPages/components/toggle.dart';
import 'package:barzzy/Backend/barhistory.dart';
import 'package:barzzy/Backend/drink.dart';
import 'package:barzzy/Backend/user.dart';
import 'package:barzzy/MenuPage/cart.dart';
import 'package:barzzy/MenuPage/drinkfeed.dart';
import 'package:barzzy/OrdersPage/hierarchy.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
  final Map<String, PageController> _pageControllers = {};
  final Map<String, int> _currentPageIndices = {};

  @override
  void initState() {
    super.initState();

    debugPrint('are you working or nah');
    _fetchBarData();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  PageController _getPageController(String tagName) {
    if (!_pageControllers.containsKey(tagName)) {
      _pageControllers[tagName] = PageController();
      _currentPageIndices[tagName] =
          0; // Initialize the page index for the category
    }
    return _pageControllers[tagName]!;
  }

  //LOADS DRINK IN
  Future<void> _fetchBarData() async {
    debugPrint('Fetching bar data for barId: ${widget.barId}');

    currentBar = LocalDatabase.getBarById(widget.barId);
    if (currentBar != null) {
      appBarTitle = (currentBar!.tag ?? 'Menu Page').replaceAll(' ', '');
    }

    await Provider.of<User>(context, listen: false)
        .fetchTagsAndDrinks(widget.barId);
    debugPrint('Finished fetching drinks for barId: ${widget.barId}');

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

    if (userId == 0) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginOrRegisterPage(),
        ),
        (route) => false,
      );
      return;
    }

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

    // Navigate to orders page and pass the barId
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/orders',
      (Route<dynamic> route) => false,
      arguments: barId, // Pass the barId to the PickupPage
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        Cart cart = Cart();
        cart.setBar(widget.barId); // Set the bar ID for the cart
        return cart;
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              _buildMainContent(),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: SingleChildScrollView(
            key: _listKey,
            controller: _scrollController,
            child: Consumer<User>(
              builder: (context, user, _) {
                final randomDrinks = user.getFullDrinkListByBarId(widget.barId);
                // Inside your _buildMainContent method or wherever you're using it
                return Column(
                  children: [
                    const SizedBox(height: 25),
                    if (randomDrinks['tag179']?.isNotEmpty ?? false) ...[
                      _buildDrinkSection(
                          context, 'Lager', randomDrinks['tag179']!),
                      const SizedBox(height: 50),
                    ],
                    if (randomDrinks['tag172']?.isNotEmpty ?? false) ...[
                      _buildDrinkSection(
                          context, 'Vodka', randomDrinks['tag172']!),
                      const SizedBox(height: 50),
                    ],
                    if (randomDrinks['tag175']?.isNotEmpty ?? false) ...[
                      _buildDrinkSection(
                          context, 'Tequila', randomDrinks['tag175']!),
                      const SizedBox(height: 50),
                    ],
                    if (randomDrinks['tag174']?.isNotEmpty ?? false) ...[
                      _buildDrinkSection(
                          context, 'Whiskey', randomDrinks['tag174']!),
                      const SizedBox(height: 50),
                    ],
                    if (randomDrinks['tag173']?.isNotEmpty ?? false) ...[
                      _buildDrinkSection(
                          context, 'Gin', randomDrinks['tag173']!),
                      const SizedBox(height: 50),
                    ],
                    if (randomDrinks['tag176']?.isNotEmpty ?? false) ...[
                      _buildDrinkSection(
                          context, 'Brandy', randomDrinks['tag176']!),
                      const SizedBox(height: 50),
                    ],
                    if (randomDrinks['tag177']?.isNotEmpty ?? false) ...[
                      _buildDrinkSection(
                          context, 'Rum', randomDrinks['tag177']!),
                      const SizedBox(height: 50),
                    ],
                    if (randomDrinks['tag186']?.isNotEmpty ?? false) ...[
                      _buildDrinkSection(
                          context, 'Seltzer', randomDrinks['tag186']!),
                      const SizedBox(height: 50),
                    ],
                    if (randomDrinks['tag178']?.isNotEmpty ?? false) ...[
                      _buildDrinkSection(
                          context, 'Ale', randomDrinks['tag178']!),
                      const SizedBox(height: 50),
                    ],
                    if (randomDrinks['tag183']?.isNotEmpty ?? false) ...[
                      _buildDrinkSection(
                          context, 'Red Wine', randomDrinks['tag183']!),
                      const SizedBox(height: 50),
                    ],
                    if (randomDrinks['tag184']?.isNotEmpty ?? false) ...[
                      _buildDrinkSection(
                          context, 'White Wine', randomDrinks['tag184']!),
                      const SizedBox(height: 50),
                    ],
                    if (randomDrinks['tag181']?.isNotEmpty ?? false) ...[
                      _buildDrinkSection(
                          context, 'Virgin', randomDrinks['tag181']!),
                      const SizedBox(height: 50),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.3),
            width: 0.25,
          ),
        ),
        color: Colors.black, // Removed gradient
      ),
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              FontAwesomeIcons.caretLeft,
              color: Colors.white54,
              size: 25,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Center(
            child: Text(
              appBarTitle,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Consumer<Cart>(
            builder: (context, cart, _) {
              return IconButton(
                icon: Icon(
                  FontAwesomeIcons.solidStar,
                  color: cart.points
                      ? Colors.amber
                      : Colors.white24, // Change color based on points
                  size: 18,
                ),
                onPressed: () {
                  Flushbar(
                    messageText: Row(
                      children: [
                        const Spacer(),
                        Icon(
                            Icons.star,
                            color: cart.points ? Colors.amber : Colors.white24,
                          ),
                          const SizedBox(width: 7),
                        Text(
                          "You have ${cart.barPoints} points!",
                          style: const TextStyle(
                            color: Colors.white, // Customize the message color
                            fontSize: 16,
                          ),
                          textAlign: TextAlign
                              .center, // Ensure the text is centered within the widget
                        ),
                          const Spacer(),
                      ],
                    ),
                    backgroundColor: Colors.black,
                    duration: const Duration(seconds: 1),
                    flushbarPosition: FlushbarPosition.TOP,
                    borderRadius: BorderRadius.circular(8),
                    margin: const EdgeInsets.all(10),
                  ).show(context);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Consumer<Cart>(
      builder: (context, cart, _) {
        if (cart.getTotalDrinkCount() == 0) {
          return const SizedBox.shrink();
        } else {
          return Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: GestureDetector(
                onTap: () {
                  _submitOrder(context);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 350, // Control the width of the button
                        maxHeight: 60, // Control the height of the button
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey
                              .withOpacity(0.3), // Semi-transparent background
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'CONFIRM',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildDrinkSection(
      BuildContext context, String tagName, List<int> drinkIds) {
    const int itemsPerPage = 6; // Number of drinks per page
    final int pageCount = (drinkIds.length / itemsPerPage)
        .ceil(); // Calculate total number of pages
    final double boxHeight = drinkIds.length > 3 ? 521.0 : 260.5;

    PageController pageController =
        _getPageController(tagName); // Get the PageController for this category

    return Column(
      children: [
        // Display the tag header and page index in a row
        Padding(
          padding: const EdgeInsets.only(bottom: 15, left: 10, right: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tagName,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (pageCount > 1)
                Text(
                  '${_currentPageIndices[tagName]! + 1} / $pageCount', // Current page index
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ),

        // Display the drink grid
        SizedBox(
          height: boxHeight,
          child: PageView.builder(
            controller: pageController,
            itemCount: pageCount, // Total number of pages
            scrollDirection: Axis.horizontal, // Horizontal swipe between pages
            onPageChanged: (index) {
              setState(() {
                _currentPageIndices[tagName] =
                    index; // Update the current page index for this category
              });
            },
            itemBuilder: (context, pageIndex) {
              // Determine the start and end indices for the drinks on the current page
              final startIndex = pageIndex * itemsPerPage;
              final endIndex =
                  (startIndex + itemsPerPage).clamp(0, drinkIds.length);

              return GridView.custom(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(), // Disable internal scrolling
                gridDelegate: SliverQuiltedGridDelegate(
                  crossAxisCount: 3, // Same as your original grid setup
                  mainAxisSpacing: 2.5,
                  crossAxisSpacing: 2.5,
                  repeatPattern: QuiltedGridRepeatPattern.same,
                  pattern: [
                    const QuiltedGridTile(2, 1),
                    const QuiltedGridTile(2, 1),
                    const QuiltedGridTile(2, 1),
                  ],
                ),
                childrenDelegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // Get the drink by its ID using your LocalDatabase provider
                    final drink = Provider.of<LocalDatabase>(context,
                            listen: false)
                        .getDrinkById(drinkIds[startIndex + index].toString());

                    // final drink = LocalDatabase().getDrinkById(drinkIds[startIndex + index].toString());

                    return GestureDetector(
                      onTap: () {
                        final cart = Provider.of<Cart>(context, listen: false);
                        Navigator.of(context).push(_createRoute(drink, cart));
                      },
                      onLongPress: () {
                        HapticFeedback.heavyImpact();
                        Provider.of<Cart>(context, listen: false)
                            .addDrink(drink.id, context);
                        FocusScope.of(context).unfocus();
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CachedNetworkImage(
                                imageUrl: drink.image,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned.fill(
                              child: Consumer<Cart>(
                                builder: (context, cart, _) {
                                  int drinkQuantities =
                                      cart.getDrinkQuantity(drink.id);

                                  if (drinkQuantities > 0) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'x$drinkQuantities',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 30,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    );
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: endIndex -
                      startIndex, // Limit the number of drinks on this page
                ),
              );
            },
          ),
        ),
      ],
    );
  }

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

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
