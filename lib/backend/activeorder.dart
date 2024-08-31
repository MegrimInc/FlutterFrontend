import 'package:flutter/material.dart';

class DrinkOrder {
  String id;
  String drinkName;
  String quantity;

  DrinkOrder(
    this.id,
    this.drinkName,
    this.quantity,
  );

  // Factory constructor to create a DrinkOrder from JSON
  factory DrinkOrder.fromJson(Map<String, dynamic> json) {
    return DrinkOrder(
      json['id'].toString(),         // Convert id to String
      json['drinkName'],             // Assuming drinkName is a String
      json['quantity'].toString(),   // Convert quantity to String
    );
  }
}

class CustomerOrder {
  String barId;
  int userId;
  double price;
  List<DrinkOrder> drinks; // Change to List<DrinkOrder>
  String status;
  String claimer;
  int timestamp;

  CustomerOrder(
    this.barId,
    this.userId,
    this.price,
    this.drinks, // Change to List<DrinkOrder>
    this.status,
    this.claimer,
    this.timestamp,
  );

  // Factory constructor for creating a CustomerOrder from JSON data
  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    debugPrint('Parsing JSON data: $json');

    List<DrinkOrder> drinks = []; // Initialize the List<DrinkOrder>

    if (json['drinks'] != null) {
      debugPrint('Parsing drinks...');
      drinks = (json['drinks'] as List)
          .map((drinkJson) => DrinkOrder.fromJson(drinkJson))
          .toList(); // Convert each item in the list to a DrinkOrder
    }

    return CustomerOrder(
      json['barId'].toString(), // Convert barId to String
      json['userId'] as int,
      (json['price'] as num).toDouble(),
      drinks, // Use parsed drinks
      json['status'] as String,
      json['claimer'] as String,
      int.parse(json['timestamp']),
    );
  }


  // Getter methods
  double? getPrice() {
    return price;
  }

  int getAge() {
    int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
    Duration ageDuration = DateTime.fromMillisecondsSinceEpoch(currentTimestamp)
        .difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
    return ageDuration.inSeconds;
  }

  int getDrinkQuantity(String drinkName) {
    return drinks
        .firstWhere((drink) => drink.drinkName == drinkName,
            orElse: () => DrinkOrder('', '', '0'))
        .quantity as int;
  }
}
