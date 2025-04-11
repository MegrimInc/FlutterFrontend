class Customer {
  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;

  Customer({
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      brand: json['brand'] as String,
      last4: json['last4'] as String,
      expMonth: int.parse(json['exp_month'].toString()),
      expYear: int.parse(json['exp_year'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brand': brand,
      'last4': last4,
      'exp_month': expMonth,
      'exp_year': expYear,
    };
  }

  @override
  String toString() {
    return "Customer(brand: $brand, last4: $last4, expMonth: $expMonth, expYear: $expYear)";
  }
}