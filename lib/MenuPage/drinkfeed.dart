import 'package:barzzy_app1/Backend/drink.dart';
import 'package:barzzy_app1/OrdersPage/cart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  State<DrinkFeed> createState() => _DrinkFeedState();
}

class _DrinkFeedState extends State<DrinkFeed> {
  Offset? _startPosition;
  static const double swipeThreshold = 50.0;

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
                widget.cart.addDrink(widget.barId, widget.drink.id);
              } else if (dy > 0) {
                widget.cart.removeDrink(widget.barId, widget.drink.id);
              }
            }
          },
          
          child: Stack(
            children: [

              Positioned.fill(
                child: Image.network(
                  widget.drink.image,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Consumer<Cart>(
                  builder: (context, cart, _) {
                    int drinkQuantities =
                        cart.getDrinkQuantity(widget.barId, widget.drink.id);
                
                    // Only render the container if drinkQuantities is greater than 0
                    if (drinkQuantities > 0) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'x$drinkQuantities',
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 140,
                                fontWeight: FontWeight.w200),
                          ),
                        ),
                      );
                    } else {
                      return const SizedBox
                          .shrink(); // Render an empty widget if drinkQuantities is 0
                    }
                  },
                ),
              ),
              Positioned(
                bottom: 250,
                right: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 75,
                      width: 75,
                      child: FloatingActionButton(
                         elevation: 0, // Remove elevation shadow
          highlightElevation: 0, // Remove highlight elevation shadow
          focusElevation: 0, // Remove focus elevation shadow
                        backgroundColor: Colors.transparent,
                        heroTag: 'add_button',
                        onPressed: () {
                          // Increment drink quantity

                          widget.cart.addDrink(widget.barId, widget.drink.id);
                        },
                        child: InkWell(
                          splashColor: Colors.transparent, // Remove splash effect
                          highlightColor: Colors.transparent, // Remove highlight effect
                          onTap: () {
                            widget.cart.addDrink(widget.barId, widget.drink.id);
                          },
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 45,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    SizedBox(
                      height: 75,
                      width: 75,
                      child: FloatingActionButton(
                         elevation: 0, // Remove elevation shadow
          highlightElevation: 0, // Remove highlight elevation shadow
          focusElevation: 0, // Remove focus elevation shadow
                        backgroundColor: Colors.transparent,
                        heroTag: 'remove_button',
                        onPressed: () {
                          // Decrement drink quantity

                          widget.cart
                              .removeDrink(widget.barId, widget.drink.id);
                        },
                        child: InkWell(
                          splashColor: Colors.transparent, // Remove splash effect
                          highlightColor: Colors.transparent, // Remove highlight effect
                          onTap: () {
                            widget.cart.removeDrink(widget.barId, widget.drink.id);
                          },
                          child: const Icon(
                            Icons.remove,
                            color: Colors.white,
                            size: 45,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 50,
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  //color: Colors.black.withOpacity(0.5),
                  padding: const EdgeInsets.fromLTRB(16.0, 13.0, 16.0, 16.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '`${widget.drink.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                ),
                        ),
                        const Spacer(),
                        
                        Padding(
                          padding: const EdgeInsets.only(left: 3, right: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                            
                              Text(
                                'ABV: ${widget.drink.alcohol}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                            '\$${widget.drink.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                                             
                            ],
                          ),
                        ),
                        const SizedBox(height:20)
                      ]),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
