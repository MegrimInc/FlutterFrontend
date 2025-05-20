
// Same as https://github.com/BarzzyLLC/RedisMicroService/blob/0.0.0/src/main/java/edu/help/dto/Order.java.
//This version is the future version, supposed to replace activeorder.dart.

class TerminalOrder {
  int merchantId; // Stored as a String on the frontend, converted to int for JSON
  int customerId;
  double totalRegularPrice;
  double totalGratuity;
  bool inAppPayments;
  List<ItemOrder> items;
  String status;
  String terminal;
  int timestamp; // Stored as an int on the frontend, converted to String for JSON
  String sessionId;
  String
      name; // The name that is displayed whenever an order is created. Does not need to be unique. OrderId will be the same.
  bool pointOfSale;

  TerminalOrder(
      this.merchantId,
      this.customerId,
      this.totalRegularPrice,
      this.totalGratuity,
      this.inAppPayments,
      this.items,
      this.status,
      this.terminal,
      this.timestamp,
      this.sessionId,
      this.name,
      this.pointOfSale);

  // Factory constructor for creating a CustomerOrder from JSON data
  factory TerminalOrder.fromJson(Map<String, dynamic> json) {
    //debugPrint('Parsing JSON data: $json');

    List<ItemOrder> items = [];
    if (json['items'] != null) {
     // debugPrint('Parsing items...');
      items = (json['items'] as List)
          .map((itemJson) => ItemOrder.fromJson(itemJson))
          .toList();
    }

    return TerminalOrder(
        json['merchantId'] as int, // Convert merchantId to String for frontend storage
        json['customerId'] as int,
        (json['totalRegularPrice'] as num).toDouble(),
        (json['totalGratuity'] as num).toDouble(),
        json['inAppPayments'] as bool,
        items,
        json['status'] as String,
        json['terminal'] as String,
        int.parse(
            json['timestamp']), // Convert timestamp to int for frontend storage
        json['sessionId'] as String,
        json['name'] as String,
        json['pointOfSale'] as bool
        );
  }

  // Method to convert a CustomerOrder instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'merchantId': (merchantId), // Convert merchantId back to int for JSON
      'customerId': customerId,
      'totalRegularPrice': totalRegularPrice,
      'totalGratuity': totalGratuity,
      'inAppPayments': inAppPayments,
      'items': items.map((item) => item.toJson()).toList(),
      'status': status,
      'terminal': terminal,
      'timestamp': timestamp.toString(), // Convert timestamp to String for JSON
      'sessionId': sessionId,
      'name': name,
      'pointOfSale': pointOfSale

    };
  }

  // Getter methods
  double getTotalRegularPrice() => totalRegularPrice;
  int getCustomerId() => customerId;
  List<ItemOrder> getItems() => items;
  String getStatus() => status;
  String getTerminal() => terminal;
  int getTimestamp() => timestamp;
  bool getInAppPayments() => inAppPayments;
  double getTotalGratuity() => totalGratuity;
  String getSessionId() => sessionId;
  String getDisplayName() => name;

  // Setter methods
  void setMerchantId(int value) => merchantId = value;
  void setCustomerId(int value) => customerId = value;
  void setTotalRegularPrice(double value) => totalRegularPrice = value;
  void setTotalGratuity(double value) => totalGratuity = value;
  void setInAppPayments(bool value) => inAppPayments = value;
  void setItems(List<ItemOrder> value) => items = value;
  void setStatus(String value) => status = value;
  void setTerminal(String value) => terminal = value;
  void setTimestamp(int value) => timestamp = value;
  void setSessionId(String value) => sessionId = value;
  void setDisplayName(String value) => name = value;

  // Helper methods
  int getAge() {
    int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
    Duration ageDuration = DateTime.fromMillisecondsSinceEpoch(currentTimestamp)
        .difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
    return ageDuration.inSeconds;
  }
}

class ItemOrder {
  int itemId;
  String itemName;
  String paymentType;
  int quantity;

  ItemOrder(
    this.itemId,
    this.itemName,
    this.paymentType,
    this.quantity,
  );

  // Factory constructor to create a ItemOrder from JSON
  factory ItemOrder.fromJson(Map<String, dynamic> json) {
    return ItemOrder(
      json['itemId'] as int,
      json['itemName'] as String,
      json['paymentType'] as String,
      json['quantity'] as int,
    );
  }

  // Method to convert a ItemOrder instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'paymentType': paymentType,
      'quantity': quantity,
    };
  }
}