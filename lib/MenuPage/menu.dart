// ignore_for_file: use_build_context_synchronously

import 'dart:ui';

import 'package:barzzy_app1/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy_app1/Backend/barhistory.dart';
import 'package:barzzy_app1/Backend/drink.dart';
import 'package:barzzy_app1/Backend/user.dart';
import 'package:barzzy_app1/MenuPage/cart.dart';
import 'package:barzzy_app1/MenuPage/drinkfeed.dart';
import 'package:barzzy_app1/OrdersPage/hierarchy.dart';
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

class MenuPageState extends State<MenuPage> with SingleTickerProviderStateMixin {
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
      appBarTitle = (currentBar!.tag ?? 'Menu Page').replaceAll(' ', '');
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
              _buildBottomBar(), // Add the floating button above the content
              // ORDER SWIPE
            Consumer<Cart>(
              builder: (context, cart, _) {
                // Check if there are items in the cart
                if (cart.getTotalDrinkCount() == 0) {
                  return Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 27.5, // Adjust this width as needed
                    child: GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if (details.velocity.pixelsPerSecond.dx < -50) {
                          final user =
                              Provider.of<User>(context, listen: false);
                          user.triggerUIUpdate();
                        }
                      },
                      child: Container(
                        color: Colors.transparent, // Invisible swipe area
                      ),
                    ),
                  );
                } else {
                  return const SizedBox.shrink(); // Render an empty widget if the cart is empty
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
    return Column(
      children: [
        _buildTopBar(),

        Expanded(
          child: SingleChildScrollView(
            key: _listKey,
            controller: _scrollController,
            child: Consumer<User>(
              builder: (context, user, _) {
                final randomDrinks = user.getRandomDrinksByBarId(widget.barId);

                return Column(
                  children: [
                    const SizedBox(height: 17.5),
                    if (randomDrinks['tag179']?.isNotEmpty ?? false)
                      _buildTagHeader('Lager'),
                    _buildDrinkGrid(context, randomDrinks['tag179']!),
                    const SizedBox(height: 30),
                    if (randomDrinks['tag172']?.isNotEmpty ?? false)
                      _buildTagHeader('Vodka'),
                    _buildDrinkGrid(context, randomDrinks['tag172']!),
                    const SizedBox(height: 30),
                    if (randomDrinks['tag175']?.isNotEmpty ?? false)
                      _buildTagHeader('Tequila'),
                    _buildDrinkGrid(context, randomDrinks['tag175']!),
                    const SizedBox(height: 30),
                     if (randomDrinks['tag174']?.isNotEmpty ?? false)
                      _buildTagHeader('Whiskey'),
                    _buildDrinkGrid(context, randomDrinks['tag174']!),
                    const SizedBox(height: 30),
                    if (randomDrinks['tag173']?.isNotEmpty ?? false)
                      _buildTagHeader('Gin'),
                    _buildDrinkGrid(context, randomDrinks['tag173']!),
                    const SizedBox(height: 30),
                    if (randomDrinks['tag176']?.isNotEmpty ?? false)
                      _buildTagHeader('Brandy'),
                    _buildDrinkGrid(context, randomDrinks['tag176']!),
                    const SizedBox(height: 30),
                    if (randomDrinks['tag177']?.isNotEmpty ?? false)
                      _buildTagHeader('Rum'),
                    _buildDrinkGrid(context, randomDrinks['tag177']!),
                    const SizedBox(height: 30),
                     if (randomDrinks['tag186']?.isNotEmpty ?? false)
                      _buildTagHeader('Seltzer'),
                    _buildDrinkGrid(context, randomDrinks['tag186']!),
                    const SizedBox(height: 30),
                    if (randomDrinks['tag178']?.isNotEmpty ?? false)
                      _buildTagHeader('Ale'),
                    _buildDrinkGrid(context, randomDrinks['tag178']!),
                    const SizedBox(height: 30),
                    if (randomDrinks['tag183']?.isNotEmpty ?? false)
                      _buildTagHeader('Red Wine'),
                    _buildDrinkGrid(context, randomDrinks['tag183']!),
                    const SizedBox(height: 30),
                    if (randomDrinks['tag184']?.isNotEmpty ?? false)
                      _buildTagHeader('White Wine'),
                    _buildDrinkGrid(context, randomDrinks['tag184']!),
                    const SizedBox(height: 30),
                    if (randomDrinks['tag181']?.isNotEmpty ?? false)
                      _buildTagHeader('Virgin'),
                    _buildDrinkGrid(context, randomDrinks['tag181']!),
                    const SizedBox(height: 30),
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
              color: Colors.white,
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
                fontWeight: FontWeight.bold
              ),
            ),
          ),
          Consumer<Cart>(
            builder: (context, cart, _) {
              bool hasItemsInCart = cart.getTotalDrinkCount() > 0;
              return IconButton(
                onPressed: hasItemsInCart
                    ? null
                    : () {
                        final user = Provider.of<User>(context, listen: false);
                        user.triggerUIUpdate();
                      },
                icon: Icon(
                  FontAwesomeIcons.forward,
                  size: 20,
                  color: hasItemsInCart ? Colors.grey : Colors.white,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTagHeader(String tagName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 17.5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          tagName,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
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
                        color: Colors.grey.withOpacity(0.3), // Semi-transparent background
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

  Widget _buildDrinkGrid(BuildContext context, List<int> drinkIds) {
    return GridView.custom(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverQuiltedGridDelegate(
        crossAxisCount: 3,
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
          final barDatabase =
              Provider.of<LocalDatabase>(context, listen: false);
          final drink = barDatabase.getDrinkById(drinkIds[index].toString());

          return GestureDetector(
            onLongPress: () {
              HapticFeedback.heavyImpact();

              final cart = Provider.of<Cart>(context, listen: false);
              Navigator.of(context).push(_createRoute(
                drink,
                cart,
              ));
            },
            onTap: () {
              HapticFeedback.lightImpact();
              Provider.of<Cart>(context, listen: false).addDrink(drink.id);
              FocusScope.of(context).unfocus();
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
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
                        int drinkQuantities = cart.getDrinkQuantity(drink.id);

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
                                  fontWeight: FontWeight.w500
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
        childCount: drinkIds.length > 6 ? 6 : drinkIds.length,
      ),
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