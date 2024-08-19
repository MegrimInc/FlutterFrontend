  class Order {
    int barId;
    int orderId;
    int userId;
    double price;
    List<String> name;
    String status;
    String claimer;
    int timestamp; // Add timestamp field to store milliseconds since epoch

    Order(
      this.barId,
      this.orderId,
      this.userId,
      this.price,
      this.name,
      this.status,
      this.claimer,
      this.timestamp, // Initialize timestamp in the constructor
    );


    // Factory constructor for creating an Order from JSON data
    factory Order.fromJson(Map<String, dynamic> json) {
      return Order(
        json['barId'] as int,
        json['orderId'] as int,
        json['userId'] as int,
        (json['price'] as num).toDouble(),
        List<String>.from(json['name'] as List), // Parse 'name' from JSON
        json['status'] as String, // Parse 'orderState' from JSON
        json['claimer'] as String, // Parse 'claimer' from JSON
        json['timestamp'] as int, // Parse 'timestamp' from JSON
      );
    }

    // Method to convert Order to JSON
    Map<String, dynamic> toJson() {
      return {
        'barId': barId,
        'orderId': orderId,
        'userId': userId,
        'price': price,
        'name': name,
        'status': status,
        'claimer': claimer,
        'timestamp': timestamp,
      };
    }

    // Method to get the age of the order in seconds
    int getAge() {
      // Get the current time in milliseconds since epoch
      int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Calculate the duration in seconds
      Duration ageDuration = DateTime.fromMillisecondsSinceEpoch(currentTimestamp)
          .difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
      
      // Return the age in seconds
      return ageDuration.inSeconds;
    }

    // Getter methods
    double? getPrice() {
      return price;
    }

  }
