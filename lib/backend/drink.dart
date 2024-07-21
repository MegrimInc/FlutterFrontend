class Drink {
  String id;
  String name;
  double alcohol;
  String image;
  
  Drink(
    this.id,
    this.name,
    this.alcohol,
    this.image,
  );

  // Getter methods
  String? getName() {
    return name;
  }

  double? getAlcohol() {
    return alcohol;
  }

  String? getImage() {
    return image;
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'alcohol': alcohol,
      'image': image,
    };
  }

  // JSON deserialization
  factory Drink.fromJson(Map<String, dynamic> json) {
    return Drink(
      json['id'] as String,
      json['name'] as String,
      (json['alcohol'] as num).toDouble(),
      json['image'] as String,
    );
  }
}
