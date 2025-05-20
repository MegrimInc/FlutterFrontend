// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:ui';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:barzzy/UI/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy/UI/AuthPages/components/toggle.dart';
import 'package:barzzy/Backend/database.dart';
import 'package:barzzy/Backend/websocket.dart';
import 'package:barzzy/config.dart';
import 'package:http/http.dart' as http;
import 'package:barzzy/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barzzy/DTO/item.dart';
import 'package:barzzy/Backend/cart.dart';
import 'package:shimmer/shimmer.dart';

class CheckoutPage extends StatefulWidget {
  final Item item;
  final Cart cart;
  final int merchantId;
  final int initialPage;
  final String? terminal;

  const CheckoutPage({
    super.key,
    required this.item,
    required this.cart,
    required this.merchantId,
    this.initialPage = 0,
    this.terminal,
  });

  @override
  CheckoutPageState createState() => CheckoutPageState();
}

class CheckoutPageState extends State<CheckoutPage>
    with SingleTickerProviderStateMixin {
  Offset? _startPosition;
  static const double swipeThreshold = 50.0;
  late AnimationController _controller;
  late Animation<double> _blurAnimation;
  late PageController _pageController; // Controller for the PageView
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);
  late ValueNotifier<Item> currentItem;

  @override
  void initState() {
    super.initState();
    currentItem = ValueNotifier(widget.item);
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
    getCardDetails();
  }

  void _submitOrder(BuildContext context, {required bool inAppPayments}) async {
    final loginCache = Provider.of<LoginCache>(context, listen: false);
    final customerId = await loginCache.getUID();
    final cart = Provider.of<Cart>(context, listen: false);
    final websocket = Provider.of<Websocket>(context, listen: false);
    final localDatabase = Provider.of<LocalDatabase>(context, listen: false);

    if (customerId == 0) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginOrRegisterPage()),
        (route) => false,
      );
      _showLoginAlertDialog(context);
      return;
    }

    // If inAppPayments is false, show a dialog and exit early.
    if (!inAppPayments &&
        localDatabase.paymentStatus == PaymentStatus.notPresent) {
      _showNotAllowedDialog(
          "Your cart only contains point-based items. Please add at least one item with a regular price to proceed.");
      return;
    }

    if (inAppPayments &&
        localDatabase.paymentStatus == PaymentStatus.notPresent) {
      try {
        _showStripeSetupSheet(context, customerId);
        return;
      } catch (e) {
        debugPrint('Error presenting Stripe setup sheet: $e');
        return;
      }
    }

    // Determine the quantity limit based on payment method
    const quantityLimit = 10;
    final totalQuantity = cart.getTotalItemCount();

    // Check if the cart's total quantity exceeds the limit
    if (totalQuantity > quantityLimit) {
      const message = 'You can only add up to 10 items per order';

      _showNotAllowedDialog(message);
      return; // Exit if limit is exceeded
    }

    final localPoints = cart.merchantPoints ?? 0;
    final earnedPoints = cart.getEarnedPointsFromCart();
    final usedPoints = cart.totalCartPoints;
    final availablePoints = localPoints + earnedPoints - usedPoints;

    if (availablePoints < 0) {
      const message = 'You do not have enough points to place this order.';
      _showNotAllowedDialog(message);
      return; // Exit if not enough points
    }

    final merchantId = widget.merchantId;

    // Build the list of item orders with variations
    List<Map<String, dynamic>> itemOrders =
        cart.merchantCart.entries.expand((entry) {
      final itemId = entry.key;

      // Process each type entry for the item
      return entry.value.entries.map((typeEntry) {
        final typeKey = typeEntry.key;
        final quantity = typeEntry.value;

        // Determine payment type
        final isPoints = typeKey.contains("points");

        // Construct the item order map
        return {
          "itemId": itemId,
          "quantity": quantity,
          "paymentType": isPoints ? "points" : "regular",
        };
      }).toList();
    }).toList();

    // Calculate the total regular price for all items paid with money

    // Prepare the order object to send
    final order = {
      "action": "create",
      "merchantId": merchantId,
      "customerId": customerId,
      "items": itemOrders,
      "isDiscount": cart.isDiscount,
      if (widget.terminal != null) "terminal": widget.terminal,
    };

    websocket.createOrder(order);
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/orders',
      (Route<dynamic> route) => false,
      arguments: merchantId,
    );
  }

  Future<void> _showStripeSetupSheet(
      BuildContext context, int customerId) async {
    final localDatabase = Provider.of<LocalDatabase>(context, listen: false);

    try {
      // Call your backend to create a SetupIntent and retrieve the client secret
      final response = await http.get(
        Uri.parse(
            '${AppConfig.postgresApiBaseUrl}/customer/createSetupIntent/$customerId'),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
         debugPrint('Full response data: $responseData'); 
        final setupIntentClientSecret = responseData["setupIntentClientSecret"];
        final stripeId = responseData["customerId"];
        final setupIntentId = setupIntentClientSecret.split('_secret_')[0];
        debugPrint('SetupIntent Response Body: ${response.body}');

        // Initialize the payment sheet with the SetupIntent
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            setupIntentClientSecret: setupIntentClientSecret,
            customerId: stripeId,
            merchantDisplayName: "Megrim",
            style: ThemeMode.system,
            allowsDelayedPaymentMethods: true, // Required for Apple Pay
            applePay: const PaymentSheetApplePay(
              merchantCountryCode: 'US',
            ),
          ),
        );

        localDatabase.updatePaymentStatus(PaymentStatus.loading);
        await Stripe.instance.presentPaymentSheet();
        await _savePaymentMethodToDatabase(
            customerId, stripeId, setupIntentId);
        localDatabase.updatePaymentStatus(PaymentStatus.present);
      } else {
        if (localDatabase.customer != null) {
          localDatabase.updatePaymentStatus(PaymentStatus.present);
        } else {
          localDatabase.updatePaymentStatus(PaymentStatus.notPresent);
        }
        debugPrint(
            "Failed to load setup intent data. Status code: ${response.statusCode}");
        debugPrint("Error Response Body: ${response.body}");
      }
    } catch (e) {
      if (localDatabase.customer != null) {
        localDatabase.updatePaymentStatus(PaymentStatus.present);
      } else {
        localDatabase.updatePaymentStatus(PaymentStatus.notPresent);
      }
      debugPrint('Error presenting Stripe setup sheet: $e');
    }
  }

// Private method to save the payment method to the database
  Future<void> _savePaymentMethodToDatabase(
      int customerId, String stripeId, String setupIntentId) async {
    try {
      final response = await http.post(
        Uri.parse(
            '${AppConfig.postgresApiBaseUrl}/customer/addPaymentIdToDatabase'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "customerId":
              customerId, // customerId is the customer Id for your app
          "stripeId": stripeId, // Stripe customer Id returned by Stripe
          "setupIntentId": setupIntentId // SetupIntent Id from Stripe
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("Payment method successfully saved to database.");
        await getCardDetails();
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
          onPanUpdate: (details) {
            if (_startPosition != null) {
              final currentPosition = details.globalPosition;
              final dy = currentPosition.dy - _startPosition!.dy;
              final dx = currentPosition.dx - _startPosition!.dx;

              // If vertical drag is greater than horizontal and has passed threshold
              if (dy > 50 && dy.abs() > dx.abs()) {
                Navigator.of(context).pop();
                _startPosition = null; // Prevent multiple pops
              }
            }
          },
          onPanEnd: (details) {
            _startPosition = null; // Always reset after swipe
          },
          child: Stack(
            children: [
              ValueListenableBuilder<Item>(
                valueListenable: currentItem,
                builder: (context, item, child) {
                  return CachedNetworkImage(
                    imageUrl: item.image,
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
                      child: Consumer<Cart>(
                        builder: (context, cart, _) {
                          final isCartEmpty = cart.getTotalItemCount() == 0;
                          return PageView(
                            controller: _pageController,
                            onPageChanged: (int page) {
                              _currentPageNotifier.value = page;
                            },
                            physics: isCartEmpty
                                ? const NeverScrollableScrollPhysics()
                                : const BouncingScrollPhysics(),
                            children: [
                              ValueListenableBuilder<Item>(
                                valueListenable: currentItem,
                                builder: (context, item, _) {
                                  return _buildItemPage(
                                      context); // Item page rebuilds when currentItem changes
                                },
                              ),
                              ValueListenableBuilder<Item>(
                                valueListenable: currentItem,
                                builder: (context, item, _) {
                                  return _buildSummaryPage(
                                      context); // Summary page rebuilds when currentItem changes
                                },
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
      padding: const EdgeInsets.only(top: 30.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Consumer<Cart>(
            builder: (context, cart, _) {
              final localPoints = cart.merchantPoints ?? 0;
              final earnedPoints = cart.getEarnedPointsFromCart();
              final usedPoints = cart.totalCartPoints;
              final availablePoints = localPoints + earnedPoints - usedPoints;

              final textColor =
                  availablePoints < 0 ? Colors.redAccent : Colors.greenAccent;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Balance: ',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AnimatedFlipCounter(
                    value: availablePoints,
                    duration: const Duration(milliseconds: 600),
                    textStyle: GoogleFonts.poppins(
                      color: textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'pts',
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemPage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const Spacer(flex: 1),
        _buildItemInfo(context),
        const Spacer(flex: 1),
        _buildTwoButtonRow(context),
        const Spacer(flex: 1),
        Center(
          child: Shimmer.fromColors(
            baseColor: Colors.white54,
            highlightColor: Colors.white,
            period: const Duration(milliseconds: 1500),
            child: Text(
              'Swipe Down to Add More',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
        const Spacer(flex: 1),
        _buildNavigateToSummaryButton(context),
        const SizedBox(height: 50)
      ],
    );
  }

  Widget _buildSummaryPage(BuildContext context) {
    final cart = Provider.of<Cart>(context);
    final hasItems = cart.getTotalItemCount() > 0;
    final totalTax = cart.taxTotal;
    final totalGratuity = cart.totalGratuity;
    final subtotal = cart.totalCartMoney + totalGratuity + totalTax;
    final totalPoints = cart.totalCartPoints;
    final serviceFee = cart.serviceFeeTotal;
    final finalTotal = cart.finalTotal;

    String totalText;
    if (subtotal > 0 && totalPoints > 0) {
      totalText =
          'Total: \$${finalTotal.toStringAsFixed(2)} & ${totalPoints.toInt()} pts';
    } else if (subtotal > 0) {
      totalText = 'Total: \$${finalTotal.toStringAsFixed(2)}';
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
            flex: 15,
            child: Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: RawScrollbar(
                thumbColor: Colors.white,
                thickness: 3,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: cart.merchantCart.keys.map((itemId) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children:
                            cart.merchantCart[itemId]!.entries.map((entry) {
                          final item = LocalDatabase().getItemById(itemId);

                          const maxLength = 40;

                          final adjustedItemName =
                              _truncateWithEllipsis(item.name, maxLength);

                          final itemName =
                              adjustedItemName + (entry.value > 1 ? 's' : '');

                          final isDiscount = cart.isDiscount;

                          final price = (isDiscount
                              ? item.discountPrice
                              : item.regularPrice +
                                  item.regularPrice * item.taxPercent +
                                  item.regularPrice * item.gratuityPercent);

                          final priceOrPoints = entry.key.contains("points")
                              ? "${(entry.value * item.pointPrice).toInt()} pts"
                              : "\$${(entry.value * price).toStringAsFixed(2)}";

                          return GestureDetector(
                            onTap: () {
                              int newItemId = item.itemId;
                              currentItem.value =
                                  LocalDatabase().getItemById(newItemId);
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
                                      '  ${entry.value} $itemName - $priceOrPoints',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '  edit',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70, // Set to white70
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
            flex: 15,
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
            'Subtotal: \$${subtotal.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
          )),
        const SizedBox(height: 5),
        Center(
            child: Text(
          'Megrim Platform Fee: \$${serviceFee.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        )),
       const Spacer(flex: 1),
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
        GestureDetector(
          onTap: () async {
            final loginCache = Provider.of<LoginCache>(context, listen: false);
            final customerId = await loginCache.getUID();
            await _showStripeSetupSheet(context, customerId);
          },
          child: Consumer<LocalDatabase>(
            builder: (context, localDatabase, _) {
              if (localDatabase.customer != null && subtotal > 0) {
                final card = localDatabase.customer!;
                return Text.rich(
                  TextSpan(
                    text:
                        "${card.brand.toUpperCase()} **** ${card.last4},  EXP. ${card.expMonth}/${card.expYear}  ",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: "edit",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                );
              } else {
                return const Text(
                  '...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                );
              }
            },
          ),
        ),
        const Spacer(flex: 4),
        _buildPurchaseButton(context),
        const SizedBox(height: 50),
      ],
    );
  }

  String _truncateWithEllipsis(String text, int maxLength) {
    return (text.length <= maxLength)
        ? text
        : '${text.substring(0, maxLength - 3)}...';
  }

  Widget _buildItemInfo(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            currentItem.value.name,
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
                  cart.getTotalQuantityForItem(currentItem.value.itemId);

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
                currentItem.value.description,
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

  Widget _buildTwoButtonRow(BuildContext context) {
    final cart = widget.cart;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _buildButtonGroup(
            context,
            label: "Points",
            itemId: currentItem.value.itemId,
            usePoints: true,
            cart: cart,
          ),
        ),
        Expanded(
          child: _buildButtonGroup(
            context,
            label: "Regular",
            itemId: currentItem.value.itemId,
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
    required int itemId,
    required bool usePoints,
    required Cart cart,
  }) {
    final isDiscount = cart.isDiscount;
    final item = LocalDatabase().getItemById(itemId);
    final price = (isDiscount
        ? item.discountPrice
        : item.regularPrice +
            item.regularPrice * item.taxPercent +
            item.regularPrice * item.gratuityPercent);
    // Update label with the dynamic price
    final updatedLabel = usePoints
        ? "$label:  ${item.pointPrice.toInt()} pts"
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
                cart.removeItem(
                  itemId,
                  usePoints: usePoints,
                );
              },
            ),
            const SizedBox(width: 15),
            Consumer<Cart>(
              builder: (context, cart, _) {
                return Text(
                  cart
                      .getItemQuantity(
                        itemId,
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
                cart.addItem(
                  itemId,
                  usePoints: usePoints,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Button to navigate to the summary page (page 1)
  Widget _buildNavigateToSummaryButton(BuildContext context) {
    return Consumer<Cart>(
      builder: (context, cart, _) {
        final isCartEmpty = cart.getTotalItemCount() == 0;

        return Center(
          child: GestureDetector(
            onTap: isCartEmpty
                ? null
                : () {
                    _pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                    HapticFeedback.heavyImpact();
                  },
            child: Container(
              width: 300,
              height: 50,
              decoration: BoxDecoration(
                color: isCartEmpty ? Colors.white24 : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'View Summary',
                  style: GoogleFonts.poppins(
                    color: isCartEmpty ? Colors.white70 : Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPurchaseButton(BuildContext context) {
    return Consumer<Cart>(
      builder: (context, cart, _) {
        final isCartEmpty = cart.getTotalItemCount() == 0;
        final totalMoneyPrice = cart.totalCartMoney;
        final bool inAppPayments = totalMoneyPrice > 0;
        final localDatabase = Provider.of<LocalDatabase>(context);
        final bool disableButton =
            isCartEmpty || localDatabase.paymentStatus == PaymentStatus.loading;

        return Column(children: [
          Center(
            child: GestureDetector(
              onTap: disableButton
                  ? null
                  : () {
                      HapticFeedback.heavyImpact();
                      _submitOrder(context, inAppPayments: inAppPayments);
                    },
              child: Container(
                width: 300,
                height: 50,
                decoration: BoxDecoration(
                  color: isCartEmpty ? Colors.white24 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Consumer<LocalDatabase>(
                    builder: (context, localDatabase, _) {
                      if (localDatabase.paymentStatus ==
                          PaymentStatus.loading) {
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
                            ? 'Pay'
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
