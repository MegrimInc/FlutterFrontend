class Point {
  final String barId; // Bar ID as a string
  final int points;

  Point({required this.barId, required this.points});

  // Method to convert Point object to JSON
  Map<String, dynamic> toJson() {
    return {
      'barId': barId,
      'points': points,
    };
  }

  // Method to create a Point object from JSON
  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      barId: json['barId'],
      points: json['points'],
    );
  }
}