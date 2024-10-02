import 'package:barzzy/Backend/bar.dart';
import 'package:barzzy/Backend/localdatabase.dart';
import 'package:flutter/material.dart';
import 'package:barzzy/Backend/drink.dart';
import 'package:flutter/services.dart';

class Cart extends ChangeNotifier {
  String? barId;
  Map<String, int> barCart = {}; // Maps drinkId to quantity

  void setBar(String newBarId) {
    if (barId != newBarId) {
      barId = newBarId;
      barCart.clear(); // Clear the cart when switching bars
      notifyListeners();
    }
  }

  int getTotalDrinkCount() {
    return barCart.values.fold(0, (total, quantity) => total + quantity);
  }

  void addDrink(String drinkId, BuildContext context) {
    if (barId == null) {
      debugPrint('Bar ID is not set.');
      return;
    }

// Check if the total number of drinks (across all drink IDs) is already 3
    int totalDrinks = getTotalDrinkCount();
    if (totalDrinks >= 3) {
      HapticFeedback.heavyImpact();
      debugPrint('Cannot add more drinks. The cart already contains 3 drinks.');
      // Trigger a SnackBar if totalDrinks is 3 or more
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.black87,
            title: const Row(
              children: [
                SizedBox(width: 75),
                Icon(Icons.error_outline, color: Colors.redAccent),
                SizedBox(width: 5),
                Text(
                  'Oops :/',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
            content: const Text(
              'You can only add up to 3 drinks.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
      return;
    }
    Bar? bar = LocalDatabase.getBarById(barId!);
    if (bar != null) {
      LocalDatabase().getDrinkById(drinkId);
      barCart.update(drinkId, (quantity) => quantity + 1, ifAbsent: () => 1);
      debugPrint('Drink with ID $drinkId added to the cart.');
      notifyListeners();
    } else {
      debugPrint('Bar with ID $barId not found.');
    }
  }

  void removeDrink(String drinkId) {
    if (barId == null) {
      debugPrint('Bar ID is not set.');
      return;
    }

    if (barCart.containsKey(drinkId)) {
      int currentQuantity = barCart[drinkId]!;
      if (currentQuantity > 1) {
        barCart.update(drinkId, (quantity) => quantity - 1);
      } else {
        barCart.remove(drinkId);
      }
      debugPrint('Drink with ID $drinkId removed from the cart.');
      notifyListeners();
    } else {
      debugPrint('Drink with ID $drinkId not in cart.');
    }
  }

  int getDrinkQuantity(String drinkId) {
    return barCart[drinkId] ?? 0;
  }

  double calculateTotalPrice() {
    double total = 0.0;
    barCart.forEach((drinkId, quantity) {
      Drink? drink = LocalDatabase().getDrinkById(drinkId);
      total += drink.price * quantity;
      debugPrint(
          'Drink ID: $drinkId, Price: ${drink.price}, Quantity: $quantity, Subtotal: ${drink.price * quantity}');
    });
    debugPrint('Total Cart Price: $total');
    return double.parse(total.toStringAsFixed(2));
  }
}
