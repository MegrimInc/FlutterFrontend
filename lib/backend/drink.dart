class Drink {
  String id;
  String style;
  String name;
  String description;
  double price;
  double alcohol;
  String type;
  String image;
  List<String> ingredients;

  Drink(this.id, this.name, this.description, this.price, this.alcohol, this.type, this.ingredients, this.image, this.style);



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

  String? getImage() {
    return image;
  }

  String? getClass() {
    return style;
  }




  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class': style,
      'name': name,
      'description': description,
      'price': price,
      'alcohol': alcohol,
      'type': type,
      'ingredients': ingredients,
      'image': image,
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
      List<String>.from(json['ingredients'] as List<dynamic>),
      json['image'] as String,
      json['class'] as String,
    );
  }
}
