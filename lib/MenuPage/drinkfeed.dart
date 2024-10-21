// ignore_for_file: use_build_context_synchronously

import 'dart:ui';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:barzzy/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy/AuthPages/components/toggle.dart';
import 'package:barzzy/Backend/localdatabase.dart';
import 'package:barzzy/OrdersPage/hierarchy.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barzzy/Backend/drink.dart';
import 'package:barzzy/MenuPage/cart.dart';

class DrinkFeed extends StatefulWidget {
  final Drink drink;
  final Cart cart;
  final String barId;

  const DrinkFeed({
    super.key,
    required this.drink,
    required this.cart,
    required this.barId,
  });

  @override
  DrinkFeedState createState() => DrinkFeedState();
}

class DrinkFeedState extends State<DrinkFeed>
    with SingleTickerProviderStateMixin {
  Offset? _startPosition;
  static const double swipeThreshold = 50.0;
  late AnimationController _controller;
  late Animation<double> _blurAnimation;
  late PageController _pageController; // Controller for the PageView
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: 0);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _blurAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
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

    final points = cart.points;

    // Construct the order object
    final order = {
      "action": "create",
      "barId": barId,
      "userId": userId,
      "drinks": drinkQuantities,
      "points": points,
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
    return ChangeNotifierProvider.value(
      value: widget.cart,
      child: Scaffold(
        body: GestureDetector(
          onPanStart: (details) {
            _startPosition = details.globalPosition;
          },
          onPanEnd: (details) {
            if (_startPosition == null) return;

            final Offset endPosition = details.globalPosition;
            final double dy = endPosition.dy - _startPosition!.dy;

            if (dy.abs() > swipeThreshold) {
              if (dy < 0) {
                //widget.cart.addDrink(widget.drink.id, context);
                Navigator.of(context).pop();
              } else if (dy > 0) {
                //widget.cart.removeDrink(widget.drink.id);
              }
            }
          },
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: widget.drink.image,
                fit: BoxFit.cover,
                height: double.infinity,
                width: double.infinity,
              ),
              BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _blurAnimation.value,
                  sigmaY: _blurAnimation.value,
                ),
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                ),
              ),

              // PageView with the content
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(
                      context,
                    ),
                    Expanded(
                      child: Consumer<Cart>(
                        builder: (context, cart, _) {
                          return PageView.builder(
                            controller: _pageController,
                            itemCount: cart.getTotalDrinkCount() == 0 ? 1 : 2,
                            onPageChanged: (int page) {
                              _currentPageNotifier.value =
                                  page; // Notify the change
                            },
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                // First page: Full content
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Center(
                                      child: SizedBox(
                                        height: 40,
                                        child: Consumer<Cart>(
                                          builder: (context, cart, _) {
                                            return cart.getTotalDrinkCount() ==
                                                    0
                                                ? const SizedBox()
                                                : Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 12),
                                                    child: AnimatedTextKit(
                                                      animatedTexts: [
                                                        FadeAnimatedText(
                                                          'Swipe To Confirm>',
                                                          textStyle: GoogleFonts
                                                              .poppins(
                                                            color:
                                                                Colors.white54,
                                                            fontSize: 21,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                          duration:
                                                              const Duration(
                                                                  milliseconds:
                                                                      3000),
                                                        ),
                                                      ],
                                                      isRepeatingAnimation:
                                                          true, // Repeat animation
                                                      repeatForever:
                                                          true, // Loop infinitely
                                                    ),
                                                  );
                                          },
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildDrinkInfo(context),
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 30),
                                      child:
                                          _buildQuantityControlButtons(context),
                                    ),
                                    _buildBottomBar(context),
                                    const SizedBox(height: 25),
                                  ],
                                );
                              } else {
                                // Summary page: Display cart items with dynamic price and points
                                return Consumer<Cart>(
                                  builder: (context, cart, _) {
                                    final cartItems = cart.barCart.keys
                                        .toList(); // Get unique drink IDs
                                    double totalPrice = cart.points
                                        ? cart.calculateTotalPriceInPoints()
                                        : cart
                                            .calculateTotalPrice(); // Total based on selected mode

                                    return Column(
                                      children: [
                                        const SizedBox(height: 25),
                                        Text(
                                          'Summary',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white54,
                                            fontSize: 25,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.all(30),
                                          child: Divider(
                                              color: Colors.white54,
                                              thickness: .5),
                                        ),

                                        // Loop through each drink in the cart
                                        for (var drinkId in cartItems)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8.0),
                                            child: Builder(
                                              builder: (context) {
                                                Drink? drink = LocalDatabase()
                                                    .getDrinkById(drinkId);
                                                int quantity = cart
                                                    .getDrinkQuantity(drinkId);
                                                double price = cart.points
                                                    ? cart
                                                        .calculatePriceForDrinkInPoints(
                                                            drinkId)
                                                    : cart
                                                        .calculatePriceForDrink(
                                                            drinkId);

                                                return Center(
                                                  child: Text(
                                                    '${drink.name} x $quantity - ${cart.points ? '${price.toStringAsFixed(0)} pts' : '\$${price.toStringAsFixed(2)}'}',
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),

                                        const SizedBox(height: 20),

                                        // Display total price with "+ tax"
                                        Center(
                                          child: Text(
                                            cart.points
                                                ? 'Total: ${totalPrice.toStringAsFixed(0)} pts'
                                                : 'Total: \$${totalPrice.toStringAsFixed(2)} + tax',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),

                                        const Spacer(),

                                        _buildConfirmButton(),

                                       const SizedBox(height: 75)


                                      ],
                                    );
                                  },
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<Cart>(
      builder: (context, cart, _) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  FocusScope.of(context).unfocus();
                },
                child: Container(
                  color: Colors.transparent,
                  width: 75,
                  height: 50,
                  alignment: Alignment.centerLeft,
                  child: const Icon(Icons.close, size: 29, color: Colors.white),
                ),
              ),
              ValueListenableBuilder<int>(
                valueListenable: _currentPageNotifier,
                builder: (context, currentPage, child) {
                  return currentPage == 0
                      ? Text(
                          '1 / 2 ',
                          style: TextStyle(
                            color: cart.getTotalDrinkCount() == 0
                                ? Colors.transparent
                                : Colors.white, // Transparent if no drinks
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : Text(
                          '2 / 2 ',
                          style: TextStyle(
                            color: cart.getTotalDrinkCount() == 0
                                ? Colors.transparent
                                : Colors.white, // Transparent if no drinks
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrinkInfo(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.drink.name,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'ABV: ${widget.drink.alcohol}%',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 24),
          _buildPriceInfo(),
          const SizedBox(height: 24),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 25, right: 25),
              child: Text(
                widget.drink.description,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Consumer<Cart>(
          builder: (context, cart, _) {
            return _buildPriceCard(
              'Regular',
              widget.drink.price,
              isUsingPoints: !cart.points, // If points are not being used
              onTogglePoints: () => cart.togglePoints(false), // Switch to Regular price
              showDollarSign: true, // Always show $ for regular price
              targetPage: 1,
              cart: cart,
            );
          },
        ),
        const SizedBox(width: 16),
        Consumer<Cart>(
          builder: (context, cart, _) {
            return _buildPriceCard(
              '   Points    ',
              widget.drink.points, // Assuming points price
              isUsingPoints: cart.points, // If points are being used
              onTogglePoints: () => cart.togglePoints(true), // Switch to Points price
              showDollarSign: false, // Never show $ for points
              targetPage: 1,
              cart: cart,
            );
          },
        ),
      ],
    );
  }

  Widget _buildPriceCard(String label, num price,
      {
      required bool isUsingPoints,
      required VoidCallback onTogglePoints, // Keep the toggle logic
      required bool showDollarSign,
      required int targetPage, // Page to swipe to
       required Cart cart,
      }) {
    return GestureDetector(
      onTap: () {
      // Toggle between points and regular pricing
      onTogglePoints();

     if (cart.getTotalDrinkCount() > 0) {
        _pageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUsingPoints ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isUsingPoints ? Colors.black : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              // Display price or points based on context
              showDollarSign
                  ? '\$${price.toStringAsFixed(2)}' // Always display price as double with $ sign
                  : '${price.toInt()}', // Always display points as integer with no $ sign
              style: GoogleFonts.poppins(
                color: isUsingPoints ? Colors.black : Colors.white70,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControlButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            heroTag: 'decrease',
            backgroundColor: Colors.white54,
            shape: const CircleBorder(),
            onPressed: () {
              widget.cart.removeDrink(widget.drink.id);
            },
            child: const Icon(Icons.remove, color: Colors.black),
          ),
          const SizedBox(width: 100),
          FloatingActionButton(
            heroTag: 'increase',
            backgroundColor: Colors.white54,
            shape: const CircleBorder(),
            onPressed: () {
              widget.cart.addDrink(widget.drink.id, context);
            },
            child: const Icon(Icons.add, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Spacer(),
          const SizedBox(width: 7.5),
          Consumer<Cart>(
            builder: (context, cart, _) => Text(
              '${cart.getDrinkQuantity(widget.drink.id)}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

   Widget _buildConfirmButton() {
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

   @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }
}
