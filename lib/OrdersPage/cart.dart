import 'package:barzzy_app1/Backend/bar.dart';
import 'package:barzzy_app1/Backend/bardatabase.dart';
import 'package:flutter/material.dart';
import 'package:barzzy_app1/Backend/drink.dart';



class Cart extends ChangeNotifier {
  
  Map<String, Map<String, int>> barCart = {};
  double totalCartPrice = 0.0;
  

  

 void addDrink(String barId, String drinkId) {
    Bar? bar = BarDatabase.getBarById(barId); // Get the Bar object
    if (bar != null) {
      Drink drink = bar.getDrinkById(drinkId); // Get the Drink object
      if (!barCart.containsKey(barId)) {
        barCart[barId] = {};
      }
      barCart[barId]!.update(drinkId, (quantity) => quantity + 1, ifAbsent: () => 1);
      totalCartPrice += drink.getPrice()!;
      totalCartPrice = double.parse(totalCartPrice.toStringAsFixed(2));
      debugPrint('Drink with ID $drinkId added to the cart for bar $barId. Total price: $totalCartPrice');
      notifyListeners(); // Notify listeners to update UI
    } else {
      debugPrint('Bar with ID $barId not found.');
    }
    
  }

  void removeDrink(String barId, String drinkId) {
    if (barCart.containsKey(barId) && barCart[barId]!.containsKey(drinkId)) {
      Bar? bar = BarDatabase.getBarById(barId); // Get the Bar object
      if (bar != null) {
        Drink drink = bar.getDrinkById(drinkId); // Get the Drink object
        int currentQuantity = barCart[barId]![drinkId]!;
        if (currentQuantity > 1) {
          barCart[barId]!.update(drinkId, (quantity) => quantity - 1);
        } else {
          barCart[barId]!.remove(drinkId);
          debugPrint('Drink with ID $drinkId removed from the cart for bar $barId. Total price: $totalCartPrice');
        }
        totalCartPrice -= drink.getPrice()!;
        totalCartPrice = double.parse(totalCartPrice.toStringAsFixed(2));
        notifyListeners(); // Notify listeners to update UI
      }
    } 
  }



  int getDrinkQuantity(String barId, String drinkId) {
    if (barCart.containsKey(barId) && barCart[barId]!.containsKey(drinkId)) {
      int quantity = barCart[barId]![drinkId]!;
      debugPrint('Drink ID: $drinkId, Quantity for bar $barId: $quantity');
      return quantity;
    } else {
      return 0; // Or any default value indicating the drink is not in the cart
    }
  }

}
