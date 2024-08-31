// ignore_for_file: use_build_context_synchronously

import 'dart:math';

import 'package:barzzy_app1/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy_app1/Backend/barhistory.dart';
import 'package:barzzy_app1/Backend/drink.dart';
import 'package:barzzy_app1/Backend/user.dart';
import 'package:barzzy_app1/MenuPage/cart.dart';
import 'package:barzzy_app1/MenuPage/drinkfeed.dart';
import 'package:barzzy_app1/OrdersPage/hierarchy.dart';
import 'package:barzzy_app1/backend/categories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
      appBarTitle = (currentBar!.tag ?? 'Menu Page').replaceAll(' ', '').toLowerCase();
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


 

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
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
                  final user = Provider.of<User>(context, listen: false);
    user.triggerUIUpdate(); // This will retrigger the random drink selection
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
            key: _listKey,
            controller: _scrollController,
            child: Consumer<User>(
              builder: (context, user, _) {
                final randomDrinks = user.getRandomDrinksByBarId(widget.barId);

                return Column(
  children: [
    if (randomDrinks['tag172']?.isNotEmpty ?? false)
      _buildDrinkGrid(context, randomDrinks['tag172']!),
    const SizedBox(height: 30),
    if (randomDrinks['tag173']?.isNotEmpty ?? false)
      _buildDrinkGrid(context, randomDrinks['tag173']!),
    const SizedBox(height: 30),
    if (randomDrinks['tag174']?.isNotEmpty ?? false)
      _buildDrinkGrid(context, randomDrinks['tag174']!),
    const SizedBox(height: 30),
    if (randomDrinks['tag175']?.isNotEmpty ?? false)
      _buildDrinkGrid(context, randomDrinks['tag175']!),
    const SizedBox(height: 30),
    if (randomDrinks['tag176']?.isNotEmpty ?? false)
      _buildDrinkGrid(context, randomDrinks['tag176']!),
    const SizedBox(height: 30),
    if (randomDrinks['tag177']?.isNotEmpty ?? false)
      _buildDrinkGrid(context, randomDrinks['tag177']!),
    const SizedBox(height: 30),
    if (randomDrinks['tag178']?.isNotEmpty ?? false)
      _buildDrinkGrid(context, randomDrinks['tag178']!),
    const SizedBox(height: 30),
    if (randomDrinks['tag179']?.isNotEmpty ?? false)
      _buildDrinkGrid(context, randomDrinks['tag179']!),
    const SizedBox(height: 30),
    if (randomDrinks['tag181']?.isNotEmpty ?? false)
      _buildDrinkGrid(context, randomDrinks['tag181']!),
    const SizedBox(height: 30),
    if (randomDrinks['tag182']?.isNotEmpty ?? false)
      _buildDrinkGrid(context, randomDrinks['tag182']!),
    const SizedBox(height: 30),
    if (randomDrinks['tag183']?.isNotEmpty ?? false)
      _buildDrinkGrid(context, randomDrinks['tag183']!),
    const SizedBox(height: 30),
    if (randomDrinks['tag184']?.isNotEmpty ?? false)
      _buildDrinkGrid(context, randomDrinks['tag184']!),
    const SizedBox(height: 30),
    if (randomDrinks['tag186']?.isNotEmpty ?? false)
      _buildDrinkGrid(context, randomDrinks['tag186']!),
    const SizedBox(height: 30),
  ],
);
              },
            ),
          ),
        ),

        // BOTTOM BAR
        Container(
          height: 67,
          child: const BottomAppBar(
            color: Colors.black,
            child: Row(
              children: [],
            ),
          ),
        ),
      ],
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
          final barDatabase = Provider.of<LocalDatabase>(context, listen: false);
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
            onDoubleTap: () {
              HapticFeedback.lightImpact();
              Provider.of<Cart>(context, listen: false).addDrink(drink.id);
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
                        int drinkQuantities = cart.getDrinkQuantity(drink.id);

                        if (drinkQuantities > 0) {
                          return Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                            ),
                            child: Center(
                              child: Text(
                                'x$drinkQuantities',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 40,
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
                  Positioned.fill(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                drink.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white54,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 15)
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

        var scaleTween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var fadeTween = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

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
    Navigator.of(context).pushNamedAndRemoveUntil('/orders', (Route<dynamic> route) => false);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}