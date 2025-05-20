class Item {
  int itemId;
  String name;
  String image;
  double regularPrice;
  double discountPrice;
  final List<int> categories;
  int pointPrice;
  String description;
  double taxPercent;
  double gratuityPercent;

  Item(
    this.itemId,
    this.name,
    this.image,
    this.regularPrice,
    this.discountPrice,
    this.categories,
    this.description,
    this.pointPrice,
    this.taxPercent,
    this.gratuityPercent
  );

  // Getter methods
  String? getName() {
    return name;
  }

  String? getImage() {
    return image;
  }

  double? getRegularPrice() {
    return regularPrice;
  }

  double? getDiscountPrice() {
    return discountPrice;
  }

  List<int> getCategories() {
    return categories;
  }

  int getPointPrice() {
    return pointPrice;
  }

  String? getDescription() {
    return description;
  }

  // Setter methods
  void setName(String value) {
    name = value;
  }

  void setImage(String value) {
    image = value;
  }

  void setRegularPricePrice(double value) {
    regularPrice = value;
  }

  void setDiscountPrice(double value) {
    discountPrice = value;
  }

  void setPointPrice(int value) {
    pointPrice = value;
  }

  void setDescription(String value) {
    description = value;
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'name': name,
      'image': image,
      'regularPrice': regularPrice,
      'discountPrice': discountPrice,
      'categories': categories,
      'description': description,
      'point': pointPrice,
      'taxPercent': taxPercent,
      'gratuityPercent': gratuityPercent
    };
  }

  // JSON deserialization
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      json['itemId'] as int,
      json['name'] as String,
      json['image'] as String,
      json['regularPrice'] as double,
      json['discountPrice'] as double,
      List<int>.from(json['categoryIds']),
      json['description'] as String,
      json['pointPrice'] as int,
      json['taxPercent'] as double,
      json['gratuityPercent'] as double,
    );
  }
}
