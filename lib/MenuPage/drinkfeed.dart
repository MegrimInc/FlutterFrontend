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
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  widget.drink.image,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 60,
                right: 30,
                child: Consumer<Cart>(
                  builder: (context, cart, _) {
                    int drinkQuantities =
                        cart.getDrinkQuantity(widget.barId, widget.drink.id);

                    // Only render the container if drinkQuantities is greater than 0
                    if (drinkQuantities > 0) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'x$drinkQuantities',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
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
                bottom: 300,
                right: 20,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 75,
                      width: 75,
                      child: FloatingActionButton(
                        backgroundColor: Colors.black54,
                        heroTag: 'add_button',
                        onPressed: () {
                          // Increment drink quantity
                          
                          widget.cart.addDrink(widget.barId, widget.drink.id);
                        },
                        
                        child: const Icon(Icons.add),
                      ),
                    ),
                    const SizedBox(height: 100,),
                    SizedBox(
                      height: 75,
                      width: 75,
                      child: FloatingActionButton(
                        backgroundColor: Colors.black54,
                        heroTag: 'remove_button',
                        onPressed: () {
                          // Decrement drink quantity
                         
                          widget.cart.removeDrink(widget.barId, widget.drink.id);
                        },
                            
                        child: const Icon(Icons.remove),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.drink.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Text(
                            //   'Price: \$${widget.drink.price.toStringAsFixed(2)}',
                            //   style: const TextStyle(
                            //     color: Colors.white,
                            //     fontSize: 18,
                            //   ),
                            // ),
                            Text(
                              'ABV: ${widget.drink.alcohol}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ])
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
