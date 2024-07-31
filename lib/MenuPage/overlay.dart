import 'dart:ui';
import 'package:barzzy_app1/MenuPage/result.dart';
import 'package:barzzy_app1/OrdersPage/cart.dart';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/heroicons_solid.dart';
import 'package:provider/provider.dart';
import 'package:barzzy_app1/Backend/user.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class HistorySheet extends StatefulWidget {
  final String barId;
  final VoidCallback onClose;

  const HistorySheet({
    super.key,
    required this.barId,
    required this.onClose,
  });

  @override
  HistorySheetState createState() => HistorySheetState();
}

class HistorySheetState extends State<HistorySheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Start the animation with a 0.05 second delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closeSheet() {
    // Reverse the animation
    _controller.reverse().then((_) {
      // Delay the onClose callback by 500 milliseconds after the reverse animation
      Future.delayed(const Duration(milliseconds: 0), widget.onClose);
    });
  }

  void _navigateToResults(BuildContext context, String query) {
  final user = Provider.of<User>(context, listen: false);
  final drinkIds = user.getSearchHistory(widget.barId)
      .firstWhere((entry) => entry.key == query)
      .value;

     final cart = Provider.of<Cart>(context, listen: false);

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Results(drinkIds: drinkIds, barId: widget.barId, cart: cart),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    // Fetch the user instance from Provider
    final user = Provider.of<User>(context);
    // Get the recent queries for the specified barId
    final recentQueries =
        user.getQueryHistory(widget.barId).reversed.take(5).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: _closeSheet,
        child: Stack(
          children: [
            // Blurred background
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: Container(
                color: Colors.transparent,
              ),
            ),
            // Display recent queries
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 25),
                Row(
                  children: [
                    const SizedBox(width: 27.5),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 100,
                        child: AnimatedTextKit(
                          animatedTexts: [
                            TyperAnimatedText(
                              'Recent',
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 35,
                                fontStyle: FontStyle.italic,
                              ),
                              speed: const Duration(milliseconds: 100),
                            ),
                          ],
                          totalRepeatCount: 1,
                          pause: const Duration(milliseconds: 1000),
                          displayFullTextOnTap: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                        colors: [
                          Colors.white.withOpacity(0.03),
                          Colors.transparent.withOpacity(0.0),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: recentQueries.length,
                      itemBuilder: (context, index) {
                        final query = recentQueries[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 29),
                          child: Row(
                            children: [
                              const SizedBox(width: 15),
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: const Iconify(
                                  HeroiconsSolid.search,
                                  size: 30,
                                  color: Color.fromARGB(200, 255, 255, 255),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => _navigateToResults(context, query),
                                child: FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Text(
                                    '$query (${user.getSearchHistory(widget.barId).firstWhere((entry) => entry.key == query).value.length})',
                                    style: const TextStyle(
                                      fontSize: 27.5,
                                      color: Color.fromARGB(225, 255, 255, 255),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
