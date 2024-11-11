import 'package:barzzy/Backend/localdatabase.dart';
import 'package:flutter/material.dart';

class Cart extends ChangeNotifier {
  int? barPoints;
  String? barId;
  Map<String, Map<String, int>> barCart = {}; // Maps drinkId to type and quantity
  Map<String, double> typeTotals = {}; // Track totals for each type combination
  bool isAddingWithPoints = false;
  Map<String, List<String>> lastAddedTypes = {};

  // Set the current bar ID and clear the cart when switching bars
  void setBar(String newBarId) {
    if (barId != newBarId) {
      barId = newBarId;
      barCart.clear(); // Clear the cart when switching bars
      typeTotals.clear(); // Reset type totals
       lastAddedTypes.clear();
      _fetchPointsForBar(newBarId);
      notifyListeners();
    }
  }

 void addDrink(String drinkId, {required bool isDouble, required bool usePoints}) {
  if (barId == null) {
    debugPrint('Bar ID is not set.');
    return;
  }

  // Define a unique type key based on both size and payment method
  final typeKey = '${isDouble ? 'double' : 'single'}_${usePoints ? 'points' : 'dollars'}';

  // Initialize the drink's map if it doesn't exist
  barCart.putIfAbsent(drinkId, () => {});
  barCart[drinkId]!.update(typeKey, (quantity) => quantity + 1, ifAbsent: () => 1);

  lastAddedTypes.putIfAbsent(drinkId, () => []).add(typeKey);

  // Update the specific price total based on single/double and points/dollars
  final drink = LocalDatabase().getDrinkById(drinkId);
  final price = (isDouble ? (usePoints ? drink.points * 2 : drink.price * 2) : (usePoints ? drink.points : drink.price)).toDouble();

  typeTotals.update(typeKey, (total) => total + price, ifAbsent: () => price);

  debugPrint('Added $typeKey of drink ID $drinkId. Updated typeTotals: $typeTotals');
  notifyListeners();
}

void removeDrink(String drinkId, {required bool isDouble, required bool usePoints}) {
  if (barId == null) {
    debugPrint('Bar ID is not set.');
    return;
  }

  final typeKey = '${isDouble ? 'double' : 'single'}_${usePoints ? 'points' : 'dollars'}';

  // Remove the entire entry for this type if it exists
  if (barCart.containsKey(drinkId) && barCart[drinkId]!.containsKey(typeKey)) {
    barCart[drinkId]!.remove(typeKey);

    // Remove the entry entirely if no quantities remain for the drink
    if (barCart[drinkId]!.isEmpty) {
      barCart.remove(drinkId);
    }

     lastAddedTypes[drinkId]?.removeWhere((key) => key == typeKey);
      if (lastAddedTypes[drinkId]?.isEmpty ?? true) {
        lastAddedTypes.remove(drinkId);
      }


    // Remove total from typeTotals
    typeTotals.remove(typeKey);
    
    debugPrint('Removed all quantities of $typeKey for drink ID $drinkId.');
    notifyListeners();
  } else {
    debugPrint('Drink with ID $drinkId and type $typeKey not in cart.');
  }
}
  // Retrieves quantity for a specific drink and type (e.g., single/double with dollars/points)
  int getDrinkQuantity(String drinkId, {required bool isDouble, required bool usePoints}) {
    final typeKey = "${isDouble ? 'double' : 'single'}_${usePoints ? 'points' : 'dollars'}";
    return barCart[drinkId]?[typeKey] ?? 0;
  }

  // New method: Retrieves the total quantity for a specific drink ID across all types
  int getTotalQuantityForDrink(String drinkId) {
    if (!barCart.containsKey(drinkId)) return 0;
    return barCart[drinkId]!.values.fold(0, (total, quantity) => total + quantity);
  }

  // Calculates total dollar amount across all types that use dollars
  double calculateTotalDollars() {
    final total = typeTotals.entries
        .where((entry) => entry.key.contains('dollars'))
        .fold(0.0, (sum, entry) => sum + entry.value);
    return double.parse(total.toStringAsFixed(2));
  }

  // Calculates total points amount across all types that use points
  double calculateTotalPoints() {
    final total = typeTotals.entries
        .where((entry) => entry.key.contains('points'))
        .fold(0.0, (sum, entry) => sum + entry.value);
    return double.parse(total.toStringAsFixed(2));
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

  // Counts the total number of unique drinks (across types) in the cart
  int getTotalDrinkCount() {
    return barCart.values.fold(0, (total, priceMap) => total + priceMap.length);
  }

  void toggleAddWithPoints() {
    isAddingWithPoints = !isAddingWithPoints;
    notifyListeners();
  }

   
  void undoLastAddition(String drinkId) {
    if (!lastAddedTypes.containsKey(drinkId) || lastAddedTypes[drinkId]!.isEmpty) {
      debugPrint('No recent addition to undo for drink ID $drinkId');
      return;
    }

    // Get the last typeKey for the drinkId and remove it from the lastAddedTypes list
    final typeKey = lastAddedTypes[drinkId]!.removeLast();

    // Check if the drink type exists in barCart before modifying
    if (barCart[drinkId] != null && barCart[drinkId]![typeKey] != null) {
      // Decrease the quantity or remove the type entry entirely
      if (barCart[drinkId]![typeKey]! > 1) {
        barCart[drinkId]![typeKey] = barCart[drinkId]![typeKey]! - 1;
      } else {
        barCart[drinkId]!.remove(typeKey);
        if (barCart[drinkId]!.isEmpty) {
          barCart.remove(drinkId);
        }
      }
      
      // Safely adjust the total for this typeKey if it exists in typeTotals
      if (typeTotals[typeKey] != null) {
        final pricePerUnit = typeTotals[typeKey]! / (barCart[drinkId]?[typeKey] ?? 1);
        typeTotals.update(typeKey, (total) => total - pricePerUnit);

        // Remove from typeTotals if the total reaches zero or below
        if (typeTotals[typeKey]! <= 0) {
          typeTotals.remove(typeKey);
        }
      }

      debugPrint('Undo last addition of $typeKey for drink ID $drinkId. Updated typeTotals: $typeTotals');
      notifyListeners();
    } else {
      debugPrint('Error: Type $typeKey for drink ID $drinkId is not in the cart.');
    }
  }


}