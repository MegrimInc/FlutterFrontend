// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:ui';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:barzzy/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy/AuthPages/components/toggle.dart';
import 'package:barzzy/Backend/localdatabase.dart';
import 'package:barzzy/OrdersPage/websocket.dart';
import 'package:http/http.dart' as http;
import 'package:barzzy/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
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
  final List<int> simpleCategoryTags = [179, 186, 183, 184, 178, 181];

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

  void _submitOrder(BuildContext context, {required bool inAppPayments}) async {
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

    // Determine the quantity limit based on payment method
    final quantityLimit = inAppPayments ? 10 : 3;
    final totalQuantity = cart.getTotalDrinkCount();

    // Check if the cart's total quantity exceeds the limit
    if (totalQuantity > quantityLimit) {
      final message = inAppPayments
          ? 'You can only add up to 10 drinks for in-app payments.'
          : 'You can only add up to 3 drinks for in-person payments.';
      _showLimitExceededDialog(message);
      return; // Exit if limit is exceeded
    }

     // Step 3: Check if the user has a payment method
  try {
    final hasPaymentMethod = await _checkPaymentMethod(userId);
    if (!hasPaymentMethod) {
      // If no payment method, show Stripe payment sheet and exit
      await _showStripeSetupSheet(context);
      return;
    }
  } catch (e) {
    debugPrint('Error checking payment method: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error: Unable to verify payment method.')),
    );
    return;
  }

    final barId = widget.barId;

    // Build the list of drink orders with variations
    List<Map<String, dynamic>> drinkOrders =
        cart.barCart.entries.expand((entry) {
      final drinkId = entry.key;
      return entry.value.entries.map((typeEntry) {
        final typeKey = typeEntry.key;
        final quantity = typeEntry.value;
        final isDouble = typeKey.contains('double');
        final isPoints = typeKey.contains('points');

        return {
          "drinkId": int.parse(drinkId),
          "quantity": quantity,
          "paymentType": isPoints ? "points" : "regular",
          "sizeType": isDouble ? "double" : "single"
        };
      }).toList();
    }).toList();

    // Calculate the total regular price for all items paid with money

    // Prepare the order object to send
    final order = {
      "action": "create",
      "barId": barId,
      "userId": userId,
      "inAppPayments": inAppPayments, // Specify payment method choice
      "drinks": drinkOrders,
      "isHappyHour": cart.isHappyHour,
    };

    hierarchy.createOrder(order);

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/orders',
      (Route<dynamic> route) => false,
      arguments: barId,
    );
  }

  // Private method to check if a payment method exists
  Future<bool> _checkPaymentMethod(int userId) async {
    final response = await http.get(Uri.parse('https://www.barzzy.site/points/checkPaymentMethod/$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body); // true if payment exists, false otherwise
    } else {
      throw Exception('Failed to check payment method');
    }
  }

  Future<void> _showStripeSetupSheet(BuildContext context) async {
  try {
    // Call your backend to create a SetupIntent and retrieve the client secret
    final response = await http.post(
      Uri.parse('https://www.barzzy.site/create-setup-intent'),
      body: jsonEncode({"customerId": "<optional-existing-customer-id>"}),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final setupIntentClientSecret = responseData["setupIntentClientSecret"];
      final customerId = responseData["customerId"];

      // Initialize the payment sheet with the SetupIntent
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          setupIntentClientSecret: setupIntentClientSecret,
          customerId: customerId,
        ),
      );

      // Present the Stripe payment sheet to collect and save payment info
      await Stripe.instance.presentPaymentSheet();
    } else {
      throw Exception("Failed to load setup intent data");
    }
  } catch (e) {
    debugPrint('Error presenting Stripe setup sheet: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Setup failed. Please try again.')),
    );
  }
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
                Navigator.of(context).pop();
              } else if (dy > 0) {
                // Possible action on swipe down
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
              SafeArea(
                child: Column(
                  children: [
                    //const SizedBox(height: 20),
                    _buildHeader(context),
                    Expanded(
                      child: Consumer<Cart>(
                        builder: (context, cart, _) {
                          final hasItems = cart.getTotalDrinkCount() > 0;
                          final totalPrice = cart.totalCartMoney;
                          final totalPoints = cart.totalCartPoints;
                          String totalText;
                          if (totalPrice > 0 && totalPoints > 0) {
                            totalText =
                                'Total: \$${totalPrice.toStringAsFixed(2)} and ${totalPoints.toInt()} pts';
                          } else if (totalPrice > 0) {
                            totalText =
                                'Total: \$${totalPrice.toStringAsFixed(2)}';
                          } else if (totalPoints > 0) {
                            totalText = 'Total: ${totalPoints.toInt()} pts';
                          } else {
                            totalText = '';
                          }

                          return PageView(
                            controller: _pageController,
                            onPageChanged: (int page) {
                              _currentPageNotifier.value =
                                  page; // Notify the change
                            },
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _buildDrinkInfo(context),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 50),
                                    child:
                                        _buildQuantityControlButtons(context),
                                  ),
                                  _buildBottomBar(context),
                                  const SizedBox(height: 25),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 25),
                                  Consumer<LocalDatabase>(
                                    builder: (context, localDatabase, _) {
                                      final pointBalance = localDatabase
                                              .getPointsForBar(widget.barId)
                                              ?.points ??
                                          0;
                                      return Center(
                                        child: SizedBox(
                                          height: 30,
                                          child: AnimatedTextKit(
                                            animatedTexts: [
                                              FadeAnimatedText(
                                                'Available Balance: $pointBalance pts',
                                                textStyle: GoogleFonts.poppins(
                                                  color: Colors.white54,
                                                  fontSize: 21,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                duration: const Duration(
                                                    milliseconds: 3000),
                                              ),
                                            ],
                                            isRepeatingAnimation: true,
                                            repeatForever: true,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 50),
                                  Center(
                                    child: Text(
                                      'Summary:',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 25,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  hasItems
                                      ? const SizedBox(height: 25)
                                      : const Spacer(),
                                  if (hasItems)
                                    // Inside your PageView's summary section
                                    Expanded(
                                      flex:
                                          20, // Allows the list area to occupy more space
                                      child: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children:
                                              cart.barCart.keys.map((drinkId) {
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: cart
                                                  .barCart[drinkId]!.entries
                                                  .map((entry) {
                                                final drink = LocalDatabase()
                                                    .getDrinkById(drinkId);
                                                final drinkName =
                                                    entry.value > 1
                                                        ? '${drink.name}s'
                                                        : drink.name;

                                                // Determine if the size label should be omitted
                                                bool shouldOmitSizeLabel(
                                                    Drink drink) {
                                                  return drink.tagId
                                                      .map((tag) =>
                                                          int.tryParse(tag) ??
                                                          -1)
                                                      .any((tag) =>
                                                          simpleCategoryTags
                                                              .contains(tag));
                                                }

                                                // Conditionally display size label based on shouldOmitSizeLabel
                                                final sizeText =
                                                    shouldOmitSizeLabel(drink)
                                                        ? '' // Omit (single)/(double) for specified categories
                                                        : (entry.key.contains(
                                                                "single")
                                                            ? " (single)"
                                                            : " (double)");

                                                // Access the cart to check if it’s happy hour
                                                final isHappyHour =
                                                    Provider.of<Cart>(context,
                                                            listen: false)
                                                        .isHappyHour;

                                              // Determine price based on whether the entry is single or double, and if it's happy hour
                                                final price = entry.key
                                                        .contains("single")
                                                    ? (isHappyHour
                                                        ? drink.singleHappyPrice
                                                        : drink.singlePrice)
                                                    : (isHappyHour
                                                        ? drink.doubleHappyPrice
                                                        : drink.doublePrice);

                                                // Format price or points based on the type key
                                                final priceOrPoints = entry.key
                                                        .contains("points")
                                                    ? "${(entry.value * drink.points).toInt()} pts"
                                                    : "\$${(entry.value * price).toStringAsFixed(2)}";

                                                return GestureDetector(
                                                  onTap: () {
                                                    _showQuantityRemovalDialog(
                                                        context,
                                                        drink, // Pass the Drink object
                                                        entry
                                                            .key, // Pass the type key (e.g., single_points or double_dollars)
                                                        entry
                                                            .value // Pass the quantity of this specific drink type
                                                        );
                                                  },
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 4.0),
                                                    child: Text(
                                                      '${entry.value} $drinkName$sizeText - $priceOrPoints',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        color: Colors.white70,
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    )
                                  else
                                    Center(
                                      child: Text(
                                        'Your cart is currently empty.',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  const Spacer(),
                                  const Padding(
                                    padding:
                                        EdgeInsets.fromLTRB(30, 7.5, 30, 15),
                                    child: Divider(
                                      color: Colors.white54,
                                      thickness: 0.5,
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      totalText, // Displays "Total: $6.99 and 500 pts" or equivalent
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  const SizedBox(height: 50),
                                  _buildPriceOptionButtons(context),
                                  if (hasItems) const SizedBox(height: 132),
                                  if (!hasItems) const SizedBox(height: 75),
                                  const Spacer(),
                                ],
                              ),
                            ],
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 50),
          ValueListenableBuilder<int>(
            valueListenable: _currentPageNotifier,
            builder: (context, currentPage, child) {
              return SizedBox(
                child: Text(
                  '${currentPage + 1} / 2 ', // Updates to show the current page out of total pages
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrinkInfo(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 22),
                SizedBox(
                  height: 30,
                  child: AnimatedTextKit(
                    animatedTexts: [
                      FadeAnimatedText(
                        'Swipe Left To View Cart',
                        textStyle: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                        ),
                        duration: const Duration(milliseconds: 3000),
                      ),
                    ],
                    isRepeatingAnimation: true, // Repeat animation
                    repeatForever: true, // Loop infinitely
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 8,
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
                Consumer<Cart>(
                  builder: (context, cart, _) {
                    final totalQuantity =
                        cart.getTotalQuantityForDrink(widget.drink.id);

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (totalQuantity > 0)
                          GestureDetector(
                            onTap: () {
                              cart.undoLastAddition(widget.drink.id);
                            },
                            child: const Icon(Icons.remove_circle,
                                color: Colors.white, size: 30),
                          ),
                        const SizedBox(
                            width: 8), // Add some space between icons
                        Text(
                          '$totalQuantity', // Display the quantity count
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    );
                  },
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
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInfo() {
    return Consumer<Cart>(
      builder: (context, cart, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                cart.toggleAddWithPoints();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color:
                      !cart.isAddingWithPoints ? Colors.white : Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Regular',
                      style: GoogleFonts.poppins(
                        color: cart.isAddingWithPoints
                            ? Colors.white
                            : Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '\$${widget.drink.singlePrice.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        color: cart.isAddingWithPoints
                            ? Colors.white70
                            : Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () {
                cart.toggleAddWithPoints();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color:
                      cart.isAddingWithPoints ? Colors.white : Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '   Points   ',
                      style: GoogleFonts.poppins(
                        color: cart.isAddingWithPoints
                            ? Colors.black
                            : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${widget.drink.points}',
                      style: GoogleFonts.poppins(
                        color: cart.isAddingWithPoints
                            ? Colors.black
                            : Colors.white70,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuantityControlButtons(BuildContext context) {
    // Check if the current drink's tag ID matches any in simpleCategoryTags
    final bool isSingleAndDoubleDifferent =
        widget.drink.singlePrice == widget.drink.doublePrice;

    return isSingleAndDoubleDifferent
        ? _buildSimpleQuantityButtons(context)
        : _buildRegularQuantityButtons(context);
  }

  Widget _buildRegularQuantityButtons(BuildContext context) {
    return Consumer<Cart>(
      builder: (context, cart, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Add 1 Double Button
            GestureDetector(
              onTap: () {
                widget.cart.addDrink(
                  widget.drink.id,
                  isDouble: true,
                  usePoints: cart.isAddingWithPoints,
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Add 1 Double',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Add 1 Single Button
            GestureDetector(
              onTap: () {
                widget.cart.addDrink(
                  widget.drink.id,
                  isDouble: false,
                  usePoints: cart.isAddingWithPoints,
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ' Add 1 Single ',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSimpleQuantityButtons(BuildContext context) {
    return Consumer<Cart>(
      builder: (context, cart, _) {
        const isDouble = false; // Always assume single for this menu
        final usePoints = cart.isAddingWithPoints;

        return Center(
          child: GestureDetector(
            onTap: () {
              widget.cart.addDrink(widget.drink.id,
                  isDouble: isDouble, usePoints: usePoints);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 19),
              decoration: BoxDecoration(
                color: Colors.white, // Use theme-appropriate color
                borderRadius: BorderRadius.circular(12), // Rounded corners
              ),
              child: Text(
                'Add 1',
                style: GoogleFonts.poppins(
                  color: Colors.black, // Text color for contrast
                  fontSize: 14, // Adjust size for a balanced look
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceOptionButtons(BuildContext context) {
    return Consumer<Cart>(
      builder: (context, cart, _) {
        final isCartEmpty = cart.getTotalDrinkCount() == 0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Pay @ bar button
            GestureDetector(
              onTap: isCartEmpty
                  ? null
                  : () => _submitOrder(context, inAppPayments: false),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: isCartEmpty ? Colors.white24 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Pay @ bar',
                      style: GoogleFonts.poppins(
                        color: isCartEmpty ? Colors.white70 : Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Pay in app button
            GestureDetector(
              onTap: isCartEmpty
                  ? null
                  : () => _submitOrder(context, inAppPayments: true),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: isCartEmpty ? Colors.white24 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Pay in app',
                      style: GoogleFonts.poppins(
                        color: isCartEmpty ? Colors.white70 : Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
        },
        child: Center(
          child: Text(
            'Order More',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _showQuantityRemovalDialog(
      BuildContext context, Drink drink, String typeKey, int quantity) {
    // Determine if the size label should be omitted based on the category
    bool shouldOmitSizeLabel(Drink drink) {
      return drink.tagId
          .map((tag) => int.tryParse(tag) ?? -1)
          .any((tag) => simpleCategoryTags.contains(tag));
    }

    // Determine size text (single/double) based on typeKey and omit if category matches simpleCategoryTags
    final sizeText = shouldOmitSizeLabel(drink)
        ? '' // No size if the category doesn't require it
        : (typeKey.contains("single") ? "single" : "double");

    // Determine payment type as "pts" or "$" based on typeKey
    final paymentType = typeKey.contains("points") ? "pts" : "\$";

    // Add plural "s" to drink name if quantity is greater than 1
    final drinkName = quantity > 1 ? '${drink.name}s' : drink.name;

    // Generate full description in parentheses with "size & payment" if both are present
    final description =
        (sizeText.isNotEmpty ? "$sizeText & " : "") + paymentType;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Center(
            child: Text(
              '($description)',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          content: Text(
            'Remove $quantity $drinkName?',
            style: GoogleFonts.poppins(
              fontSize: 21,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                  },
                  child: Text(
                    'No',
                    style: GoogleFonts.poppins(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.cart.removeDrink(drink.id,
                        isDouble: typeKey.contains("double"),
                        usePoints: typeKey.contains("points"));
                    Navigator.of(context).pop(); // Close dialog
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 0), // Adjusted padding for compactness
                  ),
                  child: Text(
                    'Yes',
                    style: GoogleFonts.poppins(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
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

  void _showLimitExceededDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                  fontSize: 22,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Center(
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
          ],
        );
      },
    );
  }
}
