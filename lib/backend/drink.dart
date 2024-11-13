class Drink {
  String id;
  String name;
  String alcohol;
  String image;
  double singlePrice;
  double singleHappyPrice;
  double doublePrice;
  double doubleHappyPrice;
  final List<String> tagId;
  int points;
  String description;

  Drink(
    this.id,
    this.name,
    this.alcohol,
    this.image,
    this.singlePrice,
    this.singleHappyPrice,
    this.doublePrice,
    this.doubleHappyPrice,
    this.tagId,
    this.description,
    this.points,
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

  double? getSinglePrice() {
    return singlePrice;
  }

  double? getSingleHappyPrice() {
    return singleHappyPrice;
  }

  double? getDoublePrice() {
    return doublePrice;
  }

  double? getDoubleHappyPrice() {
    return doubleHappyPrice;
  }

  List<String> getTagId() {
    return tagId;
  }

  int getPoints() {
    return points;
  }

  String? getDescription() {
    return description;
  }

  // Setter methods
  void setName(String value) {
    name = value;
  }

  void setAlcohol(String value) {
    alcohol = value;
  }

  void setImage(String value) {
    image = value;
  }

  void setSinglePrice(double value) {
    singlePrice = value;
  }

  void setSingleHappyPrice(double value) {
    singleHappyPrice = value;
  }

  void setDoublePrice(double value) {
    doublePrice = value;
  }

  void setDoubleHappyPrice(double value) {
    doubleHappyPrice = value;
  }

  void setPoints(int value) {
    points = value;
  }

  void setDescription(String value) {
    description = value;
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'drinkId': id,
      'drinkName': name,
      'alcoholContent': alcohol,
      'drinkImage': image,
      'singlePrice': singlePrice,
      'singleHappyPrice': singleHappyPrice,
      'doublePrice': doublePrice,
      'doubleHappyPrice': doubleHappyPrice,
      'drinkTags': tagId,
      'description': description,
      'point': points,
    };
  }

  // JSON deserialization
  factory Drink.fromJson(Map<String, dynamic> json) {
    return Drink(
      json['drinkId'].toString(),
      json['drinkName'] as String,
      json['alcoholContent'] as String,
      json['drinkImage'] as String,
      json['singlePrice'] as double,
      json['singleHappyPrice'] as double,
      json['doublePrice'] as double,
      json['doubleHappyPrice'] as double,
      (json['drinkTags'] as List<dynamic>).map((tag) => tag.toString()).toList(),
      json['description'] as String,
      json['point'] as int,
    );
  }
}