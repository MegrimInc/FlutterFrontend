import 'package:barzzy_app1/Backend/bar.dart';
import 'package:barzzy_app1/Backend/bardatabase.dart';
import 'package:flutter/material.dart';
import 'package:barzzy_app1/Backend/drink.dart';

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

  void addDrink(String drinkId) {
    if (barId == null) {
      debugPrint('Bar ID is not set.');
      return;
    }

    Bar? bar = BarDatabase.getBarById(barId!);
    if (bar != null) {
      BarDatabase().getDrinkById(drinkId);
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
      Drink? drink = BarDatabase().getDrinkById(drinkId);
      total += drink.price * quantity;
      debugPrint('Drink ID: $drinkId, Price: ${drink.price}, Quantity: $quantity, Subtotal: ${drink.price * quantity}');
        });
    debugPrint('Total Cart Price: $total');
    return double.parse(total.toStringAsFixed(2));
  }
}
