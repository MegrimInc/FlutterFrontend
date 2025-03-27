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
  final String? claimer;

  const DrinkFeed({
    super.key,
    required this.drink,
    required this.cart,
    required this.barId,
    this.initialPage = 0,
    this.claimer,
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
  late ValueNotifier<Drink> currentDrink;

  @override
  void initState() {
    super.initState();
    currentDrink = ValueNotifier(widget.drink);
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
     final localDatabase = Provider.of<LocalDatabase>(context, listen: false);

    if (userId == 0) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginOrRegisterPage()),
        (route) => false,
      );
      _showLoginAlertDialog(context);
      return;
    }

    // If inAppPayments is false, show a dialog and exit early.
    if (!inAppPayments && localDatabase.paymentStatus == PaymentStatus.notPresent) {
      _showNotAllowedDialog(
          "Your cart only contains point-based items. Please add at least one item with a regular price to proceed.");
      return;
    }

    if (inAppPayments && localDatabase.paymentStatus == PaymentStatus.notPresent) {
        try {
          _showStripeSetupSheet(context, userId);
          return;
        } catch (e) {
          debugPrint('Error presenting Stripe setup sheet: $e');
          return;
        }
    }

    // Determine the quantity limit based on payment method
    const quantityLimit = 10;
    final totalQuantity = cart.getTotalDrinkCount();

    // Check if the cart's total quantity exceeds the limit
    if (totalQuantity > quantityLimit) {
      const message = 'You can only add up to 10 drinks per order';

      _showNotAllowedDialog(message);
      return; // Exit if limit is exceeded
    }

    final availablePoints =
        localDatabase.getPointsForBar(widget.barId)?.points ?? 0;
    if (cart.totalCartPoints > availablePoints) {
      const message = 'You do not have enough points to place this order.';
      _showNotAllowedDialog(message);
      return; // Exit if not enough points
    }

    final barId = widget.barId;

    // Build the list of drink orders with variations
    List<Map<String, dynamic>> drinkOrders =
        cart.barCart.entries.expand((entry) {
      final drinkId = entry.key;

      // Process each type entry for the drink
      return entry.value.entries.map((typeEntry) {
        final typeKey =
            typeEntry.key; // Example: "single_points", "double_dollars"
        final quantity = typeEntry.value;

        // Determine the sizeType based on the typeKey
        String sizeType = "";
        if (typeKey.contains("double")) {
          sizeType = "double";
        } else if (typeKey.contains("single")) {
          sizeType = "single";
        } else {
          sizeType = ""; // No specific size type
        }

        // Determine payment type
        final isPoints = typeKey.contains("points");

        // Construct the drink order map
        return {
          "drinkId": int.parse(drinkId),
          "quantity": quantity,
          "paymentType": isPoints ? "points" : "regular",
          "sizeType": sizeType,
        };
      }).toList();
    }).toList();

    // Calculate the total regular price for all items paid with money

    final orderTip = inAppPayments ? cart.tipPercentage : 0.0;

    // Prepare the order object to send
    final order = {
      "action": "create",
      "barId": barId,
      "userId": userId,
      "inAppPayments": inAppPayments, // Specify payment method choice
      "drinks": drinkOrders,
      "happyHour": cart.isHappyHour,
      "tip": orderTip,
      if (widget.claimer != null) "claimer": widget.claimer,
    };

    hierarchy.createOrder(order);
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/orders',
      (Route<dynamic> route) => false,
      arguments: barId,
    );
  }

  Future<void> _showStripeSetupSheet(BuildContext context, int userId) async {
    final localDatabase = Provider.of<LocalDatabase>(context, listen: false);

    try {
      // Call your backend to create a SetupIntent and retrieve the client secret
      final response = await http.get(
        Uri.parse('https://www.barzzy.site/customer/createSetupIntent/$userId'),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final setupIntentClientSecret = responseData["setupIntentClientSecret"];
        final customerId = responseData["customerId"];
        final setupIntentId = setupIntentClientSecret.split('_secret_')[0];
        debugPrint('SetupIntent Response Body: ${response.body}');

        // Initialize the payment sheet with the SetupIntent
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            setupIntentClientSecret: setupIntentClientSecret,
            customerId: customerId,
            merchantDisplayName: "Barzzy",
            style: ThemeMode.system,
            allowsDelayedPaymentMethods: true, // Required for Apple Pay
            applePay: const PaymentSheetApplePay(
              merchantCountryCode: 'US',
            ),
          ),
        );

        localDatabase.updatePaymentStatus(PaymentStatus.loading);
        await Stripe.instance.presentPaymentSheet();
        await _savePaymentMethodToDatabase(userId, customerId, setupIntentId);
        localDatabase.updatePaymentStatus(PaymentStatus.present);
      } else {
        localDatabase.updatePaymentStatus(PaymentStatus.notPresent);
        debugPrint(
            "Failed to load setup intent data. Status code: ${response.statusCode}");
        debugPrint("Error Response Body: ${response.body}");
      }
    } catch (e) {
      localDatabase.updatePaymentStatus(PaymentStatus.notPresent);
      debugPrint('Error presenting Stripe setup sheet: $e');
    }
  }

// Private method to save the payment method to the database
  Future<void> _savePaymentMethodToDatabase(
      int userId, String customerId, String setupIntentId) async {
    try {
      final response = await http.post(
        Uri.parse('https://www.barzzy.site/customer/addPaymentIdToDatabase'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "customerId": userId, // userId is the customer ID for your app
          "stripeId": customerId, // Stripe customer ID returned by Stripe
          "setupIntentId": setupIntentId // SetupIntent ID from Stripe
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("Payment method successfully saved to database.");
      } else {
        debugPrint(
            "Failed to save payment method. Status code: ${response.statusCode}");
        debugPrint("Error Response Body: ${response.body}");
        throw Exception("Failed to save payment method to database.");
      }
    } catch (e) {
      debugPrint('Error saving payment method to database: $e');
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

            final double dy = details.velocity.pixelsPerSecond.dy;

            // Only trigger pop if swiping down (positive dy)
            if (dy > 100) {
              Navigator.of(context).pop();
            }

            _startPosition = null; // Reset start position
          },
          child: Stack(
            children: [
              ValueListenableBuilder<Drink>(
                valueListenable: currentDrink,
                builder: (context, drink, child) {
                  return CachedNetworkImage(
                    imageUrl: drink.image,
                    fit: BoxFit.cover,
                    height: double.infinity,
                    width: double.infinity,
                  );
                },
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
                    _buildHeader(context),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (int page) {
                          _currentPageNotifier.value = page;
                        },
                        children: [
                          ValueListenableBuilder<Drink>(
                            valueListenable: currentDrink,
                            builder: (context, drink, _) {
                              return _buildDrinkPage(
                                  context); // Drink page rebuilds when currentDrink changes
                            },
                          ),
                          ValueListenableBuilder<Drink>(
                              valueListenable: currentDrink,
                              builder: (context, drink, _) {
                                return _buildSummaryPage(
                                    context); // Summary page rebuilds when currentDrink changes
                              })
                        ],
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
      padding: const EdgeInsets.only(top: 30.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Consumer<LocalDatabase>(
            builder: (context, localDatabase, _) {
              final pointBalance =
                  localDatabase.getPointsForBar(widget.barId)?.points ?? 0;
              return Center(
                child: SizedBox(
                    height: 30,
                    child: Text(
                      'Available Balance: $pointBalance pts',
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    )),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrinkPage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const SizedBox(height: 25),
        const Spacer(flex: 1),
        _buildDrinkInfo(context),
        const Spacer(flex: 2),
        _buildQuantityControlButtons(context),
        const Spacer(flex: 2),
        Center(
          child: SizedBox(
            height: 29,
            child: Consumer<Cart>(
              builder: (context, cart, _) {
                // Show the animated text only if the cart is not empty
                return AnimatedTextKit(
                  animatedTexts: [
                    FadeAnimatedText(
                      'Swipe Left To View Cart',
                      textStyle: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                      duration: const Duration(milliseconds: 2000),
                    ),
                    FadeAnimatedText(
                      'Swipe Down to View Menu',
                      textStyle: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                      duration: const Duration(milliseconds: 2000),
                    ),
                  ],
                  isRepeatingAnimation: true,
                  repeatForever: true,
                );
              },
            ),
          ),
        ),
        const Spacer(flex: 1),
      ],
    );
  }

  Widget _buildSummaryPage(BuildContext context) {
    final cart = Provider.of<Cart>(context);
    final hasItems = cart.getTotalDrinkCount() > 0;
    final totalPrice = cart.totalCartMoney;
    final totalPoints = cart.totalCartPoints;
    final double totalPriceWithTip =
        totalPrice * (1 + cart.tipPercentage) * 1.04 + .40;
    final double serviceFee = totalPrice > 0
        ? totalPrice * (1 + cart.tipPercentage) * 0.04 + 0.40
        : 0;
    final double subtotalPriceWithTip = totalPrice * (1 + cart.tipPercentage);

    String totalText;
    if (totalPrice > 0 && totalPoints > 0) {
      totalText =
          'Total: \$${totalPriceWithTip.toStringAsFixed(2)} & ${totalPoints.toInt()} pts';
    } else if (totalPrice > 0) {
      totalText = 'Total: \$${totalPriceWithTip.toStringAsFixed(2)}';
    } else if (totalPoints > 0) {
      totalText = 'Total: ${totalPoints.toInt()} pts';
    } else {
      totalText = '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        hasItems ? const SizedBox(height: 25) : const Spacer(),
        if (hasItems)
          Expanded(
            flex: 20,
            child: Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: RawScrollbar(
                thumbColor: Colors.white,
                thickness: 3,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: cart.barCart.keys.map((drinkId) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: cart.barCart[drinkId]!.entries.map((entry) {
                          final drink = LocalDatabase().getDrinkById(drinkId);

                          final sizeText = entry.key.contains("double")
                              ? " (dbl)"
                              : entry.key.contains("single")
                                  ? " (sgl)"
                                  : "";

                          final maxLength = 21 -
                              sizeText
                                  .length; // Remaining characters allowed for the name
                          final adjustedDrinkName =
                              _truncateWithEllipsis(drink.name, maxLength);

                          final drinkName =
                              adjustedDrinkName + (entry.value > 1 ? 's' : '');

                          final isHappyHour = cart.isHappyHour;

                          final price = entry.key.contains("single")
                              ? (isHappyHour
                                      ? drink.singleHappyPrice
                                      : drink.singlePrice) *
                                  1.20
                              : (isHappyHour
                                      ? drink.doubleHappyPrice
                                      : drink.doublePrice) *
                                  1.20;

                          final priceOrPoints = entry.key.contains("points")
                              ? "${(entry.value * drink.points).toInt()} pts"
                              : "\$${(entry.value * price).toStringAsFixed(2)}";

                          return GestureDetector(
                            onTap: () {
                              String newDrinkId = drink.id;
                              currentDrink.value =
                                  LocalDatabase().getDrinkById(newDrinkId);
                              _pageController.animateToPage(
                                0,
                                duration: const Duration(
                                    milliseconds:
                                        250), // Duration of the animation
                                curve:
                                    Curves.easeInOut, // Curve for the animation
                              );
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text.rich(
                                TextSpan(
                                  text:
                                      '  ${entry.value} $drinkName$sizeText - $priceOrPoints',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '  edit',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white54, // Set to white70
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          )
        else
          Expanded(
            flex: 20,
            child: Center(
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
          ),
        const Spacer(),
        const Padding(
          padding: EdgeInsets.fromLTRB(30, 7.5, 30, 15),
          child: Divider(
            color: Colors.white54,
            thickness: 0.5,
          ),
        ),
        if (hasItems)
          Center(
              child: Text(
            'Subtotal & Fees: \$${subtotalPriceWithTip.toStringAsFixed(2)} + \$${serviceFee.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
          )),
        const SizedBox(height: 10),
        Center(
          child: Text(
            totalText,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(flex: 1),
        const SizedBox(height: 30),
        _buildPurchaseButton(context),
        const Spacer(flex: 5),
        const Text(
          '*Gratuity included in menu prices.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 18,
            fontStyle: FontStyle.italic,
            //fontWeight: FontWeight.w600
          ),
          textAlign: TextAlign.center,
        ),
        const Spacer(flex: 3),
      ],
    );
  }

  String _truncateWithEllipsis(String text, int maxLength) {
    return (text.length <= maxLength)
        ? text
        : '${text.substring(0, maxLength - 3)}...';
  }

  Widget _buildDrinkInfo(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            currentDrink.value.name,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'ABV: ${currentDrink.value.alcohol}%',
            style: GoogleFonts.poppins(
              color: Colors.white60,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 16),
          Consumer<Cart>(
            builder: (context, cart, _) {
              final totalQuantity =
                  cart.getTotalQuantityForDrink(currentDrink.value.id);

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
          const SizedBox(height: 16),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 25, right: 25),
              child: Text(
                currentDrink.value.description,
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

  Widget _buildQuantityControlButtons(BuildContext context) {
    final isDifferentPrices =
        currentDrink.value.singlePrice != currentDrink.value.doublePrice;

    // Use the passed cart instance
    final cart = widget.cart;

    return isDifferentPrices
        ? _buildFourButtonGrid(context, cart) // Grid layout for 4 buttons
        : _buildTwoButtonRow(context, cart); // Row layout for 2 buttons
  }

  Widget _buildFourButtonGrid(BuildContext context, Cart cart) {
    return Column(
      children: [
        // Top Row: Double Prices
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _buildButtonGroup(
                context,
                label: "Double",
                drinkId: currentDrink.value.id,
                isDouble: true,
                usePoints: true,
                cart: cart,
              ),
            ),
            Expanded(
              child: _buildButtonGroup(
                context,
                label: "Double",
                drinkId: currentDrink.value.id,
                isDouble: true,
                usePoints: false,
                cart: cart,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20), // Add spacing between rows

        // Bottom Row: Single Prices
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _buildButtonGroup(
                context,
                label: "Single",
                drinkId: currentDrink.value.id,
                isDouble: false,
                usePoints: true,
                cart: cart,
              ),
            ),
            Expanded(
              child: _buildButtonGroup(
                context,
                label: "Single",
                drinkId: currentDrink.value.id,
                isDouble: false,
                usePoints: false,
                cart: cart,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTwoButtonRow(BuildContext context, Cart cart) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _buildButtonGroup(
            context,
            label: "Regular",
            drinkId: currentDrink.value.id,
            isDouble: false,
            usePoints: true,
            cart: cart,
          ),
        ),
        Expanded(
          child: _buildButtonGroup(
            context,
            label: "Regular",
            drinkId: currentDrink.value.id,
            isDouble: false,
            usePoints: false,
            cart: cart,
          ),
        ),
      ],
    );
  }

  Widget _buildButtonGroup(
    BuildContext context, {
    required String label,
    required String drinkId,
    required bool isDouble,
    required bool usePoints,
    required Cart cart,
  }) {
    final isHappyHour = cart.isHappyHour;
    final drink = LocalDatabase().getDrinkById(drinkId);
    final price = isDouble
        ? (isHappyHour ? drink.doubleHappyPrice : drink.doublePrice) * 1.20
        : (isHappyHour ? drink.singleHappyPrice : drink.singlePrice) * 1.20;
    // Update label with the dynamic price
    final updatedLabel = usePoints
        ? "$label:  ${drink.points.toInt()} pts"
        : "$label:  \$${price.toStringAsFixed(2)}";

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          updatedLabel,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle),
              color: Colors.white,
              iconSize: 35,
              onPressed: () {
                cart.removeDrink(
                  drinkId,
                  isDouble: isDouble,
                  usePoints: usePoints,
                );
              },
            ),
            const SizedBox(width: 15),
            Consumer<Cart>(
              builder: (context, cart, _) {
                return Text(
                  cart
                      .getDrinkQuantity(
                        drinkId,
                        isDouble: isDouble,
                        usePoints: usePoints,
                      )
                      .toString(),
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const SizedBox(width: 15),
            IconButton(
              icon: const Icon(Icons.add_circle),
              color: Colors.white,
              iconSize: 35,
              onPressed: () {
                cart.addDrink(
                  drinkId,
                  isDouble: isDouble,
                  usePoints: usePoints,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPurchaseButton(BuildContext context) {
    return Consumer<Cart>(
      builder: (context, cart, _) {
        final isCartEmpty = cart.getTotalDrinkCount() == 0;
        final totalMoneyPrice = cart.totalCartMoney;
        final bool inAppPayments = totalMoneyPrice > 0;
        final localDatabase = Provider.of<LocalDatabase>(context);
        final bool disableButton = isCartEmpty || localDatabase.paymentStatus == PaymentStatus.loading;

        return Column(children: [
          Center(
            child: GestureDetector(
              onTap: disableButton 
                  ? null
                  : () {
                      _submitOrder(context, inAppPayments: inAppPayments);
                    },
              child: Container(
                width: 275,
                height: 50,
                decoration: BoxDecoration(
                  color: isCartEmpty ? Colors.white24 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Consumer<LocalDatabase>(
                    builder: (context, localDatabase, _) {
                      if (localDatabase.paymentStatus == PaymentStatus.loading) {
                        // When loading, show an animated loading indicator inside the button.
                        return const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.black),
                            strokeWidth: 2,
                          ),
                        );
                      } else {
                        // Otherwise, display text based on whether a payment method is present.
                        final buttonText = (localDatabase.paymentStatus ==
                                    PaymentStatus.present ||
                                !inAppPayments)
                            ? 'Purchase'
                            : 'Set up card';
                        return Text(
                          buttonText,
                          style: GoogleFonts.poppins(
                            color: isCartEmpty
                                ? Colors.white70
                                : (localDatabase.paymentStatus ==
                                            PaymentStatus.present ||
                                        !inAppPayments)
                                    ? Colors.black
                                    : Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        ]);
      },
    );
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

  void _showNotAllowedDialog(String message) {
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

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }
}

