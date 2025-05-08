import 'dart:async';

import 'package:barzzy/Backend/customer_order.dart';
import 'package:barzzy/Backend/localdatabase.dart';
import 'package:flutter/material.dart';

class Cart extends ChangeNotifier {
  int? merchantPoints;
  String? merchantId;
  Map<String, Map<String, int>> merchantCart = {}; // Maps itemId to type and quantity
  Map<String, double> typeTotals = {}; // Track totals for each type combination
  Map<String, List<String>> lastAddedTypes = {};
  double totalCartMoney = 0.0;
  int totalCartPoints = 0;
  bool isHappyHour = false;
  double tipPercentage = 0.20;
  

  // Set the current merchant Id and clear the cart when switching merchants
  void setMerchant(String newMerchantId) {
    if (merchantId != newMerchantId) {
      merchantId = newMerchantId;
      merchantCart.clear(); // Clear the cart when switching merchants
      typeTotals.clear(); // Reset type totals
      lastAddedTypes.clear();
      _fetchPointsForMerchant(newMerchantId);
      recalculateCartTotals();
      notifyListeners();
    }
  }

  void addItem(String itemId,
      { required bool usePoints}) {
    if (merchantId == null) {
      debugPrint('Merchant Id is not set.');
      return;
    }

   // Retrieve the item details
  final item = LocalDatabase().getItemById(itemId);

  final typeKey = usePoints ? 'points' : 'regular';

    // Initialize the item's map if it doesn't exist
    merchantCart.putIfAbsent(itemId, () => {});
    merchantCart[itemId]!
        .update(typeKey, (quantity) => quantity + 1, ifAbsent: () => 1);

    lastAddedTypes.putIfAbsent(itemId, () => []).add(typeKey);

    // Determine the appropriate price based on `usePoints`
    double price;
    if (usePoints) {
      price = item.pointPrice.toDouble();
    } else {
      price = item.regularPrice;
    }

    typeTotals.update(typeKey, (total) => total + price, ifAbsent: () => price);

    debugPrint(
        'Added $typeKey of item Id $itemId. Updated typeTotals: $typeTotals');
    recalculateCartTotals();
    notifyListeners();
  }


  void removeItem(String itemId,
      {required bool usePoints}) {
    if (merchantId == null) {
      debugPrint('Merchant Id is not set.');
      return;
    }

  final typeKey = usePoints ? 'points' : 'regular';
    if (merchantCart.containsKey(itemId) &&
        merchantCart[itemId]!.containsKey(typeKey)) {
      // Decrement the quantity for the specified type
      merchantCart[itemId]![typeKey] = merchantCart[itemId]![typeKey]! - 1;

      // If the quantity becomes zero, remove the type entry
      if (merchantCart[itemId]![typeKey]! <= 0) {
        merchantCart[itemId]!.remove(typeKey);

        // If no other types exist for the item, remove the item entry
        if (merchantCart[itemId]!.isEmpty) {
          merchantCart.remove(itemId);
        }

        // Clean up the lastAddedTypes for this type
        lastAddedTypes[itemId]?.remove(typeKey);
        if (lastAddedTypes[itemId]?.isEmpty ?? true) {
          lastAddedTypes.remove(itemId);
        }
      }

      // Update the total for this type in typeTotals
      if (typeTotals.containsKey(typeKey)) {
        final item = LocalDatabase().getItemById(itemId);
        final price = usePoints
            ? item.pointPrice.toInt()
            : (item.regularPrice);

        typeTotals.update(typeKey, (total) => total - price);

        // Remove the type total if it reaches zero or below
        if (typeTotals[typeKey]! <= 0) {
          typeTotals.remove(typeKey);
        }
      }

      debugPrint(
          'Removed one $typeKey of item Id $itemId. Updated typeTotals: $typeTotals');
      recalculateCartTotals();
      notifyListeners();
    } else {
      debugPrint('Item with Id $itemId and type $typeKey not found in cart.');
    }
  }

  
int getItemQuantity(String itemId,
    {required bool usePoints}) {
 
  final typeKey = usePoints ? 'points' : 'regular';

  // Return the quantity or 0 if not found
  return merchantCart[itemId]?[typeKey] ?? 0;
}

  // New method: Retrieves the total quantity for a specific item Id across all types
  int getTotalQuantityForItem(String itemId) {
    if (!merchantCart.containsKey(itemId)) return 0;
    return merchantCart[itemId]!
        .values
        .fold(0, (total, quantity) => total + quantity);
  }

  // Returns a breakdown of quantities by type and payment method for each item
  Map<String, Map<String, int>> getCartDetails() {
    return merchantCart;
  }

  Future<void> _fetchPointsForMerchant(String merchantId) async {
    final localDatabase = LocalDatabase();
    final points = localDatabase.getPointsForMerchant(merchantId);
    if (points != null) {
      merchantPoints = points.points; // Store the points in the Cart
      debugPrint('Points for merchant $merchantId: ${points.points}');
    } else {
      merchantPoints = 0; // If no points found, set to 0 or handle accordingly
      debugPrint('No points found for merchant $merchantId');
    }
    notifyListeners(); // Notify listeners to update UI or perform other actions
  }

  int getTotalItemCount() {
    return merchantCart.values.fold(0, (total, priceMap) {
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
    isHappyHour = LocalDatabase().isMerchantInHappyHour(merchantId!);

    merchantCart.forEach((itemId, itemTypes) {
      final item = LocalDatabase().getItemById(itemId);

      itemTypes.forEach((typeKey, quantity) {
        final isPoints = typeKey.contains('points');

        if (isPoints) {
          totalCartPoints += (quantity * item.pointPrice).toInt();
        } else {
          final price = (isHappyHour ? item.discountPrice : item.regularPrice);
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
  merchantCart.clear();
  typeTotals.clear();
  lastAddedTypes.clear();
  totalCartMoney = 0.0;
  totalCartPoints = 0;

  // Fetch the customer's available points balance
  final localDatabase = LocalDatabase();
  final pointsData = localDatabase.getPointsForMerchant(merchantId!);
  int availablePoints = pointsData?.points ?? 0;

  debugPrint("Customer's available points: $availablePoints");

  // Sort items by point price in descending order (expensive items first)
  List<ItemOrder> sortedItems = List.from(order.items)
    ..sort((a, b) {
      final itemA = localDatabase.getItemById(a.itemId.toString());
      final itemB = localDatabase.getItemById(b.itemId.toString());
      return (itemB.pointPrice).compareTo(itemA.pointPrice);
    });

  // Add each item from the order back to the cart
  for (var itemOrder in sortedItems) {
    final itemId = itemOrder.itemId.toString();
    final quantity = itemOrder.quantity;
    final originalPaymentType = itemOrder.paymentType; // "regular" or "points"
   

    // Retrieve the item details
    final item = localDatabase.getItemById(itemId);

    // Determine prices
    double regularPrice = item.regularPrice;
    int pointPrice = item.pointPrice; // Assume single-point price

    debugPrint(
        "Processing item $itemId | Original Payment: $originalPaymentType | Quantity: $quantity");

    int remainingQuantity = quantity;

    // First, try to assign as many as possible to points
    int pointsUsedQuantity = 0;
    while (remainingQuantity > 0 && availablePoints >= pointPrice) {
      pointsUsedQuantity++;
      availablePoints -= pointPrice;
      remainingQuantity--;
    }

   if (pointsUsedQuantity > 0) {
  String typeKey = 'points';
  merchantCart.putIfAbsent(itemId, () => {});
  merchantCart[itemId]!.update(typeKey, (currentQuantity) => currentQuantity + pointsUsedQuantity,
      ifAbsent: () => pointsUsedQuantity);
  lastAddedTypes.putIfAbsent(itemId, () => []).add(typeKey);
  typeTotals.update(typeKey, (total) => total + (pointPrice * pointsUsedQuantity).toDouble(),
      ifAbsent: () => (pointPrice * pointsUsedQuantity).toDouble());
  debugPrint("Added $pointsUsedQuantity of $itemId as points.");
}

if (remainingQuantity > 0) {
  String typeKey = 'regular';
  merchantCart.putIfAbsent(itemId, () => {});
  merchantCart[itemId]!.update(typeKey, (currentQuantity) => currentQuantity + remainingQuantity,
      ifAbsent: () => remainingQuantity);
  lastAddedTypes.putIfAbsent(itemId, () => []).add(typeKey);
  typeTotals.update(typeKey, (total) => total + (regularPrice * remainingQuantity),
      ifAbsent: () => regularPrice * remainingQuantity);
  debugPrint("Added $remainingQuantity of $itemId as regular.");
}
  }

  // Recalculate the cart totals
  recalculateCartTotals();
  notifyListeners();
}

}