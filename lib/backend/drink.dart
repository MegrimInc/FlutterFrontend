class Drink {
  String id;
  String name;
  String alcohol;
  String image;
  double price;
  double happyhourprice;
  final List<String> tagId;
  int points;
  String description; // New field for description

  Drink(this.id, this.name, this.alcohol, this.image, this.price,
      this.happyhourprice, this.tagId, this.description, this.points);

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

  String? getDescription() {
    return description;
  }



  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'drinkId': id,
      'drinkName': name,
      'alcoholContent': alcohol,
      'drinkImage': image,
      'drinkPrice': price,
      'drinkTags': tagId,
      'drinkDiscount': happyhourprice,
      'description': description, // Include the new description field
      'point': points
    };
  }

  // JSON deserialization
  factory Drink.fromJson(Map<String, dynamic> json) {
    return Drink(
      json['drinkId'].toString(),
      json['drinkName'] as String,
      json['alcoholContent'] as String,
      json['drinkImage'] as String,
      json['drinkPrice'] as double,
      json['drinkDiscount'] as double,
      (json['drinkTags'] as List<dynamic>)
          .map((tag) => tag.toString())
          .toList(),
      json['description'] as String, // Deserialize the new description field
      json['point'] as int
    );
  }
}
