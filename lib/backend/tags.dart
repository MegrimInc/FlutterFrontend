class Tag {
  final String id;
  final String name;

  Tag({required this.id, required this.name});

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['categoryId'].toString(),
      name: json['categoryName'] as String,
    );
  }
}
