import 'package:barzzy_app1/Backend/bar.dart';
import 'package:barzzy_app1/Backend/bardatabase.dart';
import 'package:flutter/material.dart';
import 'package:barzzy_app1/Backend/drink.dart';

class Cart {
  final String barId;
  List<String> drinkIds = [];
  double totalCartPrice = 0.0;

  Cart(this.barId, );

 void addDrink(String drinkId) {
    Bar? bar = BarDatabase.getBarById(barId); // Get the Bar object
    if (bar != null) {
      Drink drink = bar.getDrinkById(drinkId); // Get the Drink object
      drinkIds.add(drinkId);
      totalCartPrice += drink.getPrice()!;
      debugPrint('Drink with ID $drinkId added to the cart. Total price: $totalCartPrice');
    } else {
      debugPrint('Bar with ID $barId not found.');
    }
  }

  void removeDrink(String drinkId) {
    Bar? bar = BarDatabase.getBarById(barId); // Get the Bar object
    if (bar != null && drinkIds.contains(drinkId)) {
      Drink drink = bar.getDrinkById(drinkId); // Get the Drink object
      drinkIds.remove(drinkId);
      totalCartPrice -= drink.getPrice()!;
      debugPrint('Drink with ID $drinkId removed from the cart. Total price: $totalCartPrice');
    } else {
      debugPrint('Drink with ID $drinkId not found in the cart or Bar not found.');
    }
  }

  // Other existing methods...
}
