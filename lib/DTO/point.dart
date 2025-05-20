class Point {
  final int merchantId; // Merchant Id as a string
  final int points;

  Point({required this.merchantId, required this.points});

  // Method to convert Point object to JSON
  Map<String, dynamic> toJson() {
    return {
      'merchantId': merchantId,
      'points': points,
    };
  }

  // Method to create a Point object from JSON
  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      merchantId: int.parse(json['merchantId']),
      points: json['points'],
    );
  }
}