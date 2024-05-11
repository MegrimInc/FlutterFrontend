class Drink {
  String id;
  String name;
  String description;
  double price;
  double alcohol;
  String type;
  List<String> ingredients;

  Drink(this.id, this.name, this.description, this.price, this.alcohol, this.type, this.ingredients);



 // Getter methods
  String? getName() {
    return name;
  }
  String? getDescription() {
    return description;
  }
  double? getPrice() {
    return price;
  }
  double? getAlcohol() {
    return alcohol;
  }




  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'alcohol': alcohol,
      'type': type,
      'ingredients': ingredients,
    };
  }

  // JSON deserialization
  factory Drink.fromJson(Map<String, dynamic> json) {
    return Drink(
      json['id'] as String,
      json['name'] as String,
      json['description'] as String,
      (json['price'] as num).toDouble(),
      (json['alcohol'] as num).toDouble(),
      json['type'] as String,
      List<String>.from(json['ingredients'] as List<dynamic>)
    );
  }
}
