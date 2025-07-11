// Same as https://github.com/BarzzyLLC/RedisMicroService/blob/0.0.0/src/main/java/edu/help/dto/Order.java.
//This version is the future version, supposed to replace activeorder.dart.

import 'package:megrim/DTO/items.dart';

class CustomerOrder {
  String name;
  int merchantId; // Stored as a String on the frontend, converted to int for JSON
  int customerId;
  double totalRegularPrice;
  bool inAppPayments;
  List<Items> items;
  String status;
  int employeeId;
  int timestamp; // Stored as an int on the frontend, converted to String for JSON
  String sessionId;

  CustomerOrder(
    this.name,
    this.merchantId,
    this.customerId,
    this.totalRegularPrice,
    this.inAppPayments,
    this.items,
    this.status,
    this.employeeId,
    this.timestamp,
    this.sessionId,
  );

  // Factory constructor for creating a CustomerOrder from JSON data
  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    //debugPrint('Parsing JSON data: $json');

    List<Items> items = [];
    if (json['items'] != null) {
      //debugPrint('Parsing items...');
      items = (json['items'] as List)
          .map((itemJson) => Items.fromJson(itemJson))
          .toList();
    }

    return CustomerOrder(
      json['name'] as String,
      json['merchantId'] as int, // Convert merchantId to String for frontend storage
      json['customerId'] as int,
      (json['totalRegularPrice'] as num).toDouble(),
      json['inAppPayments'] as bool,
      items,
      json['status'] as String,
      json['employeeId'] as int,
      int.parse(
          json['timestamp']), // Convert timestamp to int for frontend storage
      json['sessionId'] as String,
    );
  }

  // Method to convert a CustomerOrder instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'merchantId': merchantId, // Convert merchantId back to int for JSON
      'customerId': customerId,
      'totalRegularPrice': totalRegularPrice,
      'inAppPayments': inAppPayments,
      'items': items.map((item) => item.toJson()).toList(),
      'status': status,
      'employeeId': employeeId,
      'timestamp': timestamp.toString(), // Convert timestamp to String for JSON
      'sessionId': sessionId,
    };
  }

  // Getter methods
  double getTotalRegularPrice() => totalRegularPrice;
  int getCustomerId() => customerId;
  List<Items> getItems() => items;
  String getStatus() => status;
  int getEmployeeId() => employeeId;
  int getTimestamp() => timestamp;
  bool getInAppPayments() => inAppPayments;
  String getSessionId() => sessionId;

  // Setter methods
  void setMerchantId(int value) => merchantId = value;
  void setCustomerId(int value) => customerId = value;
  void setTotalRegularPrice(double value) => totalRegularPrice = value;
  void setInAppPayments(bool value) => inAppPayments = value;
  void setItems(List<Items> value) => items = value;
  void setStatus(String value) => status = value;
  void setEmployeeId(int value) => employeeId = value;
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
