// ignore_for_file: use_build_context_synchronously

import 'dart:ui';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:barzzy/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy/AuthPages/components/toggle.dart';
import 'package:barzzy/Backend/localdatabase.dart';
import 'package:barzzy/OrdersPage/hierarchy.dart';
import 'package:barzzy/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barzzy/Backend/drink.dart';
import 'package:barzzy/MenuPage/cart.dart';

class DrinkFeed extends StatefulWidget {
  final Drink drink;
  final Cart cart;
  final String barId;
   final int initialPage;

  const DrinkFeed({
    super.key,
    required this.drink,
    required this.cart,
    required this.barId,
    this.initialPage = 0,
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

    _pageController = PageController(
      initialPage: widget.initialPage, // NEW: Use the initialPage from widget
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _blurAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  void _submitOrder(BuildContext context, {required bool usePoints}) async {
    final loginCache = Provider.of<LoginCache>(context, listen: false);
    final userId = await loginCache.getUID();
    final cart = Provider.of<Cart>(context, listen: false);
    final hierarchy = Provider.of<Hierarchy>(context, listen: false);

    if (userId == 0) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginOrRegisterPage()),
        (route) => false,
      );
      _showLoginAlertDialog(context);
      return;
    }

    final barId = widget.barId;
    final drinkQuantities = cart.barCart.entries.map((entry) {
      return {'drinkId': int.parse(entry.key), 'quantity': entry.value};
    }).toList();

    final order = {
      "action": "create",
      "barId": barId,
      "userId": userId,
      "drinks": drinkQuantities,
      "points": usePoints, // Use the passed-in points flag
    };

    hierarchy.createOrder(order);

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/orders',
      (Route<dynamic> route) => false,
      arguments: barId,
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

                                    return Column(
                                      children: [
                                        const SizedBox(height: 75),
                                        Text(
                                          'Summary:',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 25,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        // const Padding(
                                        //   padding: EdgeInsets.all(30),
                                        //   child: Divider(
                                        //       color: Colors.white54,
                                        //       thickness: .5),
                                        // ),
                                        const SizedBox(height: 50),
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
                                                double ptPrice = cart
                                                    .calculatePriceForDrinkInPoints(
                                                        drinkId);
                                                double regPrice =
                                                    cart.calculatePriceForDrink(
                                                        drinkId);

                                                return Center(
                                                  child: Text(
                                                    '$quantity ${quantity > 1 ? "${drink.name}s" : drink.name} - \$$regPrice or ${ptPrice.toInt()} pts',
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

                                    const Spacer(),

                                        
                                        const Padding(
                                          padding: EdgeInsets.all(30),
                                          child: Divider(
                                              color: Colors.white54,
                                              thickness: .5),
                                        ),
                                        _buildPriceOptionButtons(context),

                                         const SizedBox(height: 150),

                                        

                              
                                        
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
              showDollarSign: false, // Never show $ for points
              targetPage: 1,
              cart: cart,
            );
          },
        ),
      ],
    );
  }

  Widget _buildPriceCard(
    String label,
    num price, {
    required bool showDollarSign,
    required int targetPage, // Page to swipe to
    required Cart cart,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
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
              color: Colors.white70,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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

  // Replace _buildConfirmButton() with this method
  Widget _buildPriceOptionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPriceOption(
          context,
          label: 'Pay @ bar',
          price: widget.cart.calculateTotalPrice(),
          isPoints: false, // Indicates this is the cash option
          onTap: () => _submitOrder(context, usePoints: false),
        ),
        _buildPriceOption(
          context,
          label: 'Pay with pts',
          price: widget.cart.calculateTotalPriceInPoints(),
          isPoints: true, // Indicates this is the points option
          onTap: () => _submitOrder(context, usePoints: true),
        ),
      ],
    );
  }

  Widget _buildPriceOption(
    BuildContext context, {
    required String label,
    required double price,
    required bool isPoints, // Determines if the display is for points
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPoints
                  ? '${price.toInt()}' // Display points as an integer
                  : '\$${price.toStringAsFixed(2)}', // Display cash as dollars
                
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _showLoginAlertDialog(BuildContext context) {
    final safeContext = navigatorKey.currentContext;

    if (safeContext == null) {
      debugPrint('Safe context is null. Cannot show dialog.');
      return;
    }

    //debugPrint('Showing error dialog with safe context: $safeContext');

    showDialog(
      context: safeContext,
      builder: (BuildContext context) {
        HapticFeedback.heavyImpact();
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: const Row(
            children: [
              SizedBox(width: 75),
              Icon(Icons.error_outline, color: Colors.black),
              SizedBox(width: 5),
              Text(
                'Oops :/',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          content: const Text(
            'Log in or register to place an order.',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}
