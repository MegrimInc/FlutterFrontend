class Drink {
  String id;
  String name;
  String alcohol;
  String image;
  double price;

  Drink(
    this.id,
    this.name,
    this.alcohol,
    this.image,
    this.price
  );

  // Getter methods
  String? getName() {
    return name;
  }

  String? getAlcohol() {
    return alcohol;
  }

  String? getImage() {
    return image;
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'drinkId': id,
      'drinkName': name,
      'alcoholContent': alcohol,
      'drinkImage': image,
      'drinkPrice': price
    };
  }

  // JSON deserialization
  factory Drink.fromJson(Map<String, dynamic> json) {
    return Drink(
      json['drinkId'].toString(),
      json['drinkName'] as String,
      json['alcoholContent'] as String,
      json['drinkImage'] as String,
      json ['drinkPrice'] as double
    );
  }
}
