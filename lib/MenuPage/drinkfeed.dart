import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barzzy_app1/Backend/drink.dart';
import 'package:barzzy_app1/MenuPage/cart.dart';

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

class DrinkFeedState extends State<DrinkFeed> with SingleTickerProviderStateMixin {
  Offset? _startPosition;
  static const double swipeThreshold = 50.0;
  late AnimationController _controller;
  late Animation<double> _blurAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _blurAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.cart,
      child: Scaffold(
        body: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
            FocusScope.of(context).unfocus();
          },
          onPanStart: (details) {
            _startPosition = details.globalPosition;
          },
          onPanUpdate: (details) {
            // Optionally track the swipe progress here
          },
          onPanEnd: (details) {
            if (_startPosition == null) return;

            final Offset endPosition = details.globalPosition;
            final double dy = endPosition.dy - _startPosition!.dy;

            if (dy.abs() > swipeThreshold) {
              if (dy < 0) {
                widget.cart.addDrink(widget.drink.id);
              } else if (dy > 0) {
                widget.cart.removeDrink(widget.drink.id);
              }
            }
          },
          child: Stack(
            children: [
              // Full-screen background image with blur effect
              Positioned.fill(
                child: Stack(
                  children: [
                    Image.network(
                      widget.drink.image,
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
                  ],
                ),
              ),
              // Gradient overlay for better readability
              FadeTransition(
                opacity: _opacityAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.2),
                        Colors.grey.withOpacity(0.2),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Content
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    Expanded(child: _buildDrinkInfo(context)),
                    _buildBottomBar(context),
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
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Text(
            '1 of 1',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
        ],
      ),
    );
  }

  Widget _buildPriceInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPriceCard('Regular', widget.drink.price),
        const SizedBox(width: 16),
        _buildPriceCard('Happy Hour', widget.drink.happyhourprice, isHappyHour: true),
      ],
    );
  }

  Widget _buildPriceCard(String label, double price, {bool isHappyHour = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isHappyHour ? Colors.amber : Colors.white24,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: isHappyHour ? Colors.black : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '\$${price.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              color: isHappyHour ? Colors.black : Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
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
}
