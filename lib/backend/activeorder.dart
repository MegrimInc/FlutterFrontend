import 'package:flutter/material.dart';

// Same as https://github.com/BarzzyLLC/RedisMicroService/blob/0.0.0/src/main/java/edu/help/dto/Order.java.
//This version is the future version, supposed to replace activeorder.dart.

class CustomerOrder {
  String name; 
  String barId; // Stored as a String on the frontend, converted to int for JSON
  int userId;
  double totalRegularPrice;
  double tip;
  bool inAppPayments;
  List<DrinkOrder> drinks;
  String status;
  String claimer;
  int timestamp; // Stored as an int on the frontend, converted to String for JSON
  String sessionId;


  CustomerOrder(
    this.name,
    this.barId,
    this.userId,
    this.totalRegularPrice,
    this.tip,
    this.inAppPayments,
    this.drinks,
    this.status,
    this.claimer,
    this.timestamp,
    this.sessionId,

  );

  // Factory constructor for creating a CustomerOrder from JSON data
  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    debugPrint('Parsing JSON data: $json');

    List<DrinkOrder> drinks = [];
    if (json['drinks'] != null) {
      debugPrint('Parsing drinks...');
      drinks = (json['drinks'] as List)
          .map((drinkJson) => DrinkOrder.fromJson(drinkJson))
          .toList();
    }

    return CustomerOrder(
      json['name'] as String,
      json['barId'].toString(), // Convert barId to String for frontend storage
      json['userId'] as int,
      (json['totalRegularPrice'] as num).toDouble(),
      (json['tip'] as num).toDouble(),
      json['inAppPayments'] as bool,
      drinks,
      json['status'] as String,
      json['claimer'] as String,
      int.parse(
          json['timestamp']), // Convert timestamp to int for frontend storage
      json['sessionId'] as String,
    );
  }

  // Method to convert a CustomerOrder instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'barId': int.parse(barId), // Convert barId back to int for JSON
      'userId': userId,
      'totalRegularPrice': totalRegularPrice,
      'tip': tip,
      'inAppPayments': inAppPayments,
      'drinks': drinks.map((drink) => drink.toJson()).toList(),
      'status': status,
      'claimer': claimer,
      'timestamp': timestamp.toString(), // Convert timestamp to String for JSON
      'sessionId': sessionId,
      'name': name
    };
  }

  // Getter methods
  double getTotalRegularPrice() => totalRegularPrice;
  int getUserId() => userId;
  List<DrinkOrder> getDrinks() => drinks;
  String getStatus() => status;
  String getClaimer() => claimer;
  int getTimestamp() => timestamp;
  bool getInAppPayments() => inAppPayments;
  double getTip() => tip;
  String getSessionId() => sessionId;

  // Setter methods
  void setBarId(String value) => barId = value;
  void setUserId(int value) => userId = value;
  void setTotalRegularPrice(double value) => totalRegularPrice = value;
  void setTip(double value) => tip = value;
  void setInAppPayments(bool value) => inAppPayments = value;
  void setDrinks(List<DrinkOrder> value) => drinks = value;
  void setStatus(String value) => status = value;
  void setClaimer(String value) => claimer = value;
  void setTimestamp(int value) => timestamp = value;
  void setSessionId(String value) => sessionId = value;

  // Helper methods
  int getAge() {
    int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
    Duration ageDuration = DateTime.fromMillisecondsSinceEpoch(currentTimestamp)
        .difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
    return ageDuration.inSeconds;
  }
}

class DrinkOrder {
  int drinkId;
  String drinkName;
  String paymentType;
  String sizeType;
  int quantity;

  DrinkOrder(
    this.drinkId,
    this.drinkName,
    this.paymentType,
    this.sizeType,
    this.quantity,
  );

  // Factory constructor to create a DrinkOrder from JSON
  factory DrinkOrder.fromJson(Map<String, dynamic> json) {
    return DrinkOrder(
      json['drinkId'] as int,
      json['drinkName'] as String,
      json['paymentType'] as String,
      json['sizeType'] as String,
      json['quantity'] as int,
    );
  }

  // Method to convert a DrinkOrder instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'drinkId': drinkId,
      'drinkName': drinkName,
      'paymentType': paymentType,
      'sizeType': sizeType,
      'quantity': quantity,
    };
  }

  int getDrinkId() => drinkId;
  String getDrinkName() => drinkName;
  String getPaymentType() => paymentType;
  String getSizeType() => sizeType;
  int getQuantity() => quantity;

  List<String> get types => [sizeType, paymentType];
}
