import 'dart:async';

import 'package:barzzy/Backend/activeorder.dart';
import 'package:barzzy/Backend/localdatabase.dart';
import 'package:flutter/material.dart';

class Cart extends ChangeNotifier {
  int? barPoints;
  String? barId;
  Map<String, Map<String, int>> barCart = {}; // Maps drinkId to type and quantity
  Map<String, double> typeTotals = {}; // Track totals for each type combination
  Map<String, List<String>> lastAddedTypes = {};
  double totalCartMoney = 0.0;
  int totalCartPoints = 0;
  bool isHappyHour = false;
  double tipPercentage = 0.18;


  // Set the current bar ID and clear the cart when switching bars
  void setBar(String newBarId) {
    if (barId != newBarId) {
      barId = newBarId;
      barCart.clear(); // Clear the cart when switching bars
      typeTotals.clear(); // Reset type totals
      lastAddedTypes.clear();
      _fetchPointsForBar(newBarId);
      recalculateCartTotals();
      notifyListeners();
    }
  }

  void addDrink(String drinkId,
      {required bool isDouble, required bool usePoints}) {
    if (barId == null) {
      debugPrint('Bar ID is not set.');
      return;
    }

   // Retrieve the drink details
  final drink = LocalDatabase().getDrinkById(drinkId);

  // Determine the `sizeType` based on the drink's pricing
  String sizeType = "";
  if (drink.singlePrice != drink.doublePrice) {
    sizeType = isDouble ? "double" : "single";
  }

  // Define a unique type key using `sizeType` and `usePoints`
  final typeKey = '${sizeType}_${usePoints ? 'points' : 'dollars'}';

    // Initialize the drink's map if it doesn't exist
    barCart.putIfAbsent(drinkId, () => {});
    barCart[drinkId]!
        .update(typeKey, (quantity) => quantity + 1, ifAbsent: () => 1);

    lastAddedTypes.putIfAbsent(drinkId, () => []).add(typeKey);

    // Determine the appropriate price based on `usePoints`
    double price;
    if (usePoints) {
      price = drink.points.toDouble();
    } else {
      price = isDouble ? drink.doublePrice : drink.singlePrice;
    }

    typeTotals.update(typeKey, (total) => total + price, ifAbsent: () => price);

    debugPrint(
        'Added $typeKey of drink ID $drinkId. Updated typeTotals: $typeTotals');
    recalculateCartTotals();
    notifyListeners();
  }


  void removeDrink(String drinkId,
      {required bool isDouble, required bool usePoints}) {
    if (barId == null) {
      debugPrint('Bar ID is not set.');
      return;
    }

    // Retrieve the drink details
  final drink = LocalDatabase().getDrinkById(drinkId);

  // Determine the `sizeType` based on the drink's pricing
  String sizeType = "";
  if (drink.singlePrice != drink.doublePrice) {
    sizeType = isDouble ? "double" : "single";
  }

    // Define the typeKey using the dynamically determined sizeType
  final typeKey = '${sizeType}_${usePoints ? 'points' : 'dollars'}';
    if (barCart.containsKey(drinkId) &&
        barCart[drinkId]!.containsKey(typeKey)) {
      // Decrement the quantity for the specified type
      barCart[drinkId]![typeKey] = barCart[drinkId]![typeKey]! - 1;

      // If the quantity becomes zero, remove the type entry
      if (barCart[drinkId]![typeKey]! <= 0) {
        barCart[drinkId]!.remove(typeKey);

        // If no other types exist for the drink, remove the drink entry
        if (barCart[drinkId]!.isEmpty) {
          barCart.remove(drinkId);
        }

        // Clean up the lastAddedTypes for this type
        lastAddedTypes[drinkId]?.remove(typeKey);
        if (lastAddedTypes[drinkId]?.isEmpty ?? true) {
          lastAddedTypes.remove(drinkId);
        }
      }

      // Update the total for this type in typeTotals
      if (typeTotals.containsKey(typeKey)) {
        final drink = LocalDatabase().getDrinkById(drinkId);
        final price = usePoints
            ? drink.points.toDouble()
            : (isDouble ? drink.doublePrice : drink.singlePrice);

        typeTotals.update(typeKey, (total) => total - price);

        // Remove the type total if it reaches zero or below
        if (typeTotals[typeKey]! <= 0) {
          typeTotals.remove(typeKey);
        }
      }

      debugPrint(
          'Removed one $typeKey of drink ID $drinkId. Updated typeTotals: $typeTotals');
      recalculateCartTotals();
      notifyListeners();
    } else {
      debugPrint('Drink with ID $drinkId and type $typeKey not found in cart.');
    }
  }

  // Retrieves quantity for a specific drink and type (e.g., single/double with dollars/points)
int getDrinkQuantity(String drinkId,
    {required bool isDouble, required bool usePoints}) {
  // Retrieve the drink details
  final drink = LocalDatabase().getDrinkById(drinkId);

  // Determine the `sizeType` based on the drink's pricing
  String sizeType = "";
  if (drink.singlePrice != drink.doublePrice) {
    sizeType = isDouble ? "double" : "single";
  }

  // Define the typeKey using the dynamically determined sizeType
  final typeKey = '${sizeType}_${usePoints ? 'points' : 'dollars'}';

  // Return the quantity or 0 if not found
  return barCart[drinkId]?[typeKey] ?? 0;
}

  // New method: Retrieves the total quantity for a specific drink ID across all types
  int getTotalQuantityForDrink(String drinkId) {
    if (!barCart.containsKey(drinkId)) return 0;
    return barCart[drinkId]!
        .values
        .fold(0, (total, quantity) => total + quantity);
  }

  // Returns a breakdown of quantities by type and payment method for each drink
  Map<String, Map<String, int>> getCartDetails() {
    return barCart;
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
    return barCart.values.fold(0, (total, priceMap) {
      return total +
          priceMap.values
              .fold(0, (typeTotal, quantity) => typeTotal + quantity);
    });
  }

  // Recalculate totals and set isHappyHour based on LocalDatabase status
  void recalculateCartTotals() {
    totalCartMoney = 0.0;
    totalCartPoints = 0;

    // Get happy hour status from LocalDatabase and set isHappyHour
    isHappyHour = LocalDatabase().isBarInHappyHour(barId!);

    barCart.forEach((drinkId, drinkTypes) {
      final drink = LocalDatabase().getDrinkById(drinkId);

      drinkTypes.forEach((typeKey, quantity) {
        final isDouble = typeKey.contains('double');
        final isPoints = typeKey.contains('points');

        if (isPoints) {
          totalCartPoints += (quantity * drink.points).toInt();
        } else {
          final price = isDouble
              ? (isHappyHour ? drink.doubleHappyPrice : drink.doublePrice)
              : (isHappyHour ? drink.singleHappyPrice : drink.singlePrice);
          totalCartMoney += price * quantity;
        }
      });
    });
    notifyListeners();
  }

  void setTipPercentage(double newTipPercentage) {
  tipPercentage = newTipPercentage;
  notifyListeners(); // Notify listeners to update UI or recalculate totals
}

void reorder(CustomerOrder order) {
  // Clear the current cart
  barCart.clear();
  typeTotals.clear();
  lastAddedTypes.clear();
  totalCartMoney = 0.0;
  totalCartPoints = 0;

  // Add each drink from the order back to the cart
  for (var drinkOrder in order.drinks) {
    final drinkId = drinkOrder.drinkId.toString();
    final quantity = drinkOrder.quantity;

    // Determine type keys based on size and payment type
    final typeKey = '${drinkOrder.sizeType}_${drinkOrder.paymentType}';

    // Add the drink to the cart with the specified quantity
    barCart.putIfAbsent(drinkId, () => {});
    barCart[drinkId]!.update(typeKey, (currentQuantity) => currentQuantity + quantity, ifAbsent: () => quantity);

    // Track the type key for the drink
    lastAddedTypes.putIfAbsent(drinkId, () => []).add(typeKey);

    // Update the type totals
    final drink = LocalDatabase().getDrinkById(drinkId);
    double price = drinkOrder.paymentType == 'points'
        ? drink.points.toDouble()
        : (drinkOrder.sizeType == 'double' ? drink.doublePrice : drink.singlePrice);

    typeTotals.update(typeKey, (total) => total + (price * quantity), ifAbsent: () => price * quantity);
  }

  // Recalculate the cart totals
  recalculateCartTotals();
  notifyListeners();
}

}
