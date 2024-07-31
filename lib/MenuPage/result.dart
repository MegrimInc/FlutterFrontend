import 'package:barzzy_app1/MenuPage/drinkfeed.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:barzzy_app1/Backend/drink.dart';
import 'package:barzzy_app1/Backend/bardatabase.dart';
import 'package:barzzy_app1/OrdersPage/cart.dart';

class Results extends StatelessWidget {
  final List<String> drinkIds;
  final String barId;
  final Cart cart;

  const Results({super.key, required this.drinkIds, required this.barId, required this.cart});
  @override
  Widget build(BuildContext context) {
    final barDatabase = Provider.of<BarDatabase>(context, listen: false);
    final drinks = drinkIds.map((id) => barDatabase.getDrinkById(id)).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: drinks.isEmpty
            ? const Center(
                child: Text(
                  'No results found',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              )
            : GridView.custom(
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
                    final drink = drinks[index];
                    return GestureDetector(
                      onLongPress: () {
                        HapticFeedback.heavyImpact();

                        final cart = Provider.of<Cart>(context, listen: false);
                        Navigator.of(context).push(
                          _createRoute(drink, cart),
                        );
                      },
                      onDoubleTap: () {
                        HapticFeedback.lightImpact();
                        Provider.of<Cart>(context, listen: false)
                            .addDrink(barId, drink.id);
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
                                  int drinkQuantities = cart.getDrinkQuantity(
                                      barId, drink.id);

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
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
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
                  childCount: drinks.length,
                ),
              ),
      ),
    );
  }

  Route _createRoute(Drink drink, Cart cart) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => DrinkFeed(
        drink: drink,
        cart: cart,
        barId: barId,
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
}
