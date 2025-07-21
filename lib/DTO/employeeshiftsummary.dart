class EmployeeShiftSummary {
  final int employeeId;
  final String name;
  final double revenue;
  final double gratuity;
  final int points;

  EmployeeShiftSummary({
    required this.employeeId,
    required this.name,
    required this.revenue,
    required this.gratuity,
    required this.points,
  });

  factory EmployeeShiftSummary.fromJson(Map<String, dynamic> json) {
    return EmployeeShiftSummary(
      employeeId: json['employeeId'],
      name: json['name'],
      revenue: (json['revenue'] as num).toDouble(),
      gratuity: (json['gratuity'] as num).toDouble(),
      points: json['points'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'name': name,
      'revenue': revenue,
      'gratuity': gratuity,
      'points': points,
    };
  }
}