class Item {
  String itemId;
  String name;
  String image;
  double regularPrice;
  double discountPrice;
  final List<String> categories;
  int pointPrice;
  String description;

  Item(
    this.itemId,
    this.name,
    this.image,
    this.regularPrice,
    this.discountPrice,
    this.categories,
    this.description,
    this.pointPrice,
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

  List<String> getCategories() {
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
      'point': pointPrice
    };
  }

  // JSON deserialization
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      json['itemId'].toString(),
      json['name'] as String,
      json['image'] as String,
      json['regularPrice'] as double,
      json['discountPrice'] as double,
      (json['categoryIds'] as List<dynamic>).map((tag) => tag.toString()).toList(),
      json['description'] as String,
      json['pointPrice'] as int,
    );
  }
}