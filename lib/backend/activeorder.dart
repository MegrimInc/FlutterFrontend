import 'package:flutter/material.dart';



class CustomerOrder {
  String barId;
  int userId;
  double price;
  List<DrinkOrder> drinks; // Change to List<DrinkOrder>
  String status;
  String claimer;
  int timestamp;
  bool points;

  CustomerOrder(
    this.barId,
    this.userId,
    this.price,
    this.drinks, // Change to List<DrinkOrder>
    this.status,
    this.claimer,
    this.timestamp,
     this.points,
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
      json['points'] as bool,
    );
  }

  // Getter methods
  double? getPrice() {
    return price;
  }

  // Getter methods
  int? getUser() {
    return userId;
  }


// Getter methods
  String getBarId() {
    return barId;
  }

  int getUserId() {
    return userId;
  }

  

  List<DrinkOrder> getDrinks() {
    return drinks;
  }

  String getStatus() {
    return status;
  }

  String getClaimer() {
    return claimer;
  }

  int getTimestamp() {
    return timestamp;
  }

  bool getPoints() {
    return points;
  }

  // Setter methods
  void setBarId(String value) {
    barId = value;
  }

  void setUserId(int value) {
    userId = value;
  }

  void setPrice(double value) {
    price = value;
  }

  void setDrinks(List<DrinkOrder> value) {
    drinks = value;
  }

  void setStatus(String value) {
    status = value;
  }

  void setClaimer(String value) {
    claimer = value;
  }

  void setTimestamp(int value) {
    timestamp = value;
  }

  void setPoints(bool value) {
    points = value;
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
