import 'package:flutter/material.dart';

class CustomerOrder {
  String barId;
  int userId;
  double price;
  Map<String, int> drinkQuantities; // Map<String, int> for drink quantities
  String status;
  String claimer;
  String timestamp;

  CustomerOrder(
    this.barId,
    this.userId,
    this.price,
    this.drinkQuantities, 
    this.status,
    this.claimer,
    this.timestamp,
  );

  // Factory constructor for creating an Order from JSON data
  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    debugPrint('Parsing JSON data: $json');

    final Map<String, int> drinkQuantities = {}; // Initialize the Map<String, int>
    
    if (json['drinks'] != null) {
      debugPrint('Parsing drink quantities...');
      for (var item in json['drinks']) {
        final String drinkId = item['id'].toString(); // Convert drinkId to String
        final int quantity = item['quantity'] as int;
        debugPrint('Parsing drink ID: $drinkId, quantity: $quantity');
        drinkQuantities[drinkId] = quantity; // Store in the Map<String, int>
      }
    }

    return CustomerOrder(
      json['barId'].toString(), // Convert barId to String
      json['userId'] as int, 
      (json['price'] as num).toDouble(),
      drinkQuantities, // Use parsed drink quantities
      json['status'] as String,
      json['claimer'] as String,
      json['timestamp'] as String,
    );
  }

  get name => userId;

  // Method to convert Order to JSON
  Map<String, dynamic> toJson() {
    // Convert drink quantities to a list of maps
    final List<Map<String, dynamic>> drinkQuantitiesList = drinkQuantities.entries
        .map((entry) => {'id': entry.key, 'quantity': entry.value})
        .toList();

    return {
      'barId': barId,
      'userId': userId,
      'price': price,
      'drinks': drinkQuantitiesList,
      'status': status,
      'claimer': claimer,
      'timestamp': timestamp,
    };
  }

  // Getter methods
  double? getPrice() {
    return price;
  }

      int getAge() {
      // Get the current time in milliseconds since epoch
      int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Calculate the duration in seconds
      Duration ageDuration = DateTime.fromMillisecondsSinceEpoch(currentTimestamp)
          .difference(DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp)));
      
      // Return the age in seconds
      return ageDuration.inSeconds;
    }

    int getDrinkQuantity(String drinkId) {
    return drinkQuantities[drinkId] ?? 0;
  }

}
