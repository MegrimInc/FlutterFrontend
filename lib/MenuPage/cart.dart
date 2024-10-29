// ignore_for_file: unnecessary_null_comparison

import 'package:barzzy/Backend/bar.dart';
import 'package:barzzy/Backend/localdatabase.dart';
import 'package:flutter/material.dart';
import 'package:barzzy/Backend/drink.dart';
import 'package:flutter/services.dart';

class Cart extends ChangeNotifier {
  String? barId;
  Map<String, int> barCart = {}; // Maps drinkId to quantity
  int? barPoints;

  
  void setBar(String newBarId) {
    if (barId != newBarId) {
      barId = newBarId;
      barCart.clear(); // Clear the cart when switching bars
       _fetchPointsForBar(newBarId);
      notifyListeners();
    }
  }


  Future<void> _fetchPointsForBar(String barId) async {
    final localDatabase = LocalDatabase();
    final points = localDatabase.getPointsForBar(barId);
    if (points != null) {
      barPoints = points.points; // Store the points in the Cart
      debugPrint('Points for bar $barId: ${points.points}');
    } else {
      barPoints = 0; // If no points found, set to 0 or handle accordingly
      debugPrint('No points found for bar $barId');
    }
    notifyListeners(); // Notify listeners to update UI or perform other actions
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
              'You can only add up to 3 drinks per order!',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
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


  double calculatePriceForDrink(String drinkId) {
    Drink? drink = LocalDatabase().getDrinkById(drinkId);
    int quantity = barCart[drinkId] ?? 0;
    if (drink != null) {
      return double.parse((drink.price * quantity).toStringAsFixed(2));
    }
    return 0.0;
  }

   double calculatePriceForDrinkInPoints(String drinkId) {
    Drink? drink = LocalDatabase().getDrinkById(drinkId);
    int quantity = barCart[drinkId] ?? 0;
    if (drink != null) {
      return double.parse((drink.points.toDouble() * quantity).toStringAsFixed(2));
    }
    return 0.0;
  }

  double calculateTotalPriceInPoints() {
    double total = 0.0;
    barCart.forEach((drinkId, quantity) {
      Drink? drink = LocalDatabase().getDrinkById(drinkId);
      if (drink != null) {
        total += drink.points.toDouble() * quantity;
      }
    });
    return double.parse(total.toStringAsFixed(2));
  }
}
