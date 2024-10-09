import 'dart:ui';

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
          onPanStart: (details) {
            _startPosition = details.globalPosition;
          },
          onPanEnd: (details) {
            if (_startPosition == null) return;

            final Offset endPosition = details.globalPosition;
            final double dy = endPosition.dy - _startPosition!.dy;

            if (dy.abs() > swipeThreshold) {
              if (dy < 0) {
                widget.cart.addDrink(widget.drink.id, context);
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

              // Positioned widget on the left side for swipe detection
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 100, // Adjust this width as needed
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.velocity.pixelsPerSecond.dx > -50) {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                color: Colors
                    .transparent,
              ),
            ),
          ),
              // Content
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: _buildDrinkInfo(context),
                    ),
                   // _buildBottomBar(context),
                   Padding(
                     padding: const EdgeInsets.only(bottom: 30),
                     child: _buildQuantityControlButtons(context),
                   ),
                   _buildBottomBar(context),
                   const SizedBox(height: 25)
                  ],
                ),
              ),

              // Positioned(
              //         bottom: 105,
              //         left: 39.5,
              //         child: _buildQuantityControlButtons(context)),
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
          const Text(
            '1 / 2',
            style: TextStyle(
              color: Colors.transparent,
              fontSize: 20,
              fontWeight: FontWeight.w700,
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
        _buildPriceCard('Regular', widget.drink.price),
        const SizedBox(width: 16),
        _buildPriceCard('Happy Hour', widget.drink.happyhourprice,
            isHappyHour: true),
      ],
    );
  }

  Widget _buildPriceCard(String label, double price,
      {bool isHappyHour = false}) {
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


