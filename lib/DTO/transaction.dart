import 'package:megrim/DTO/items.dart';

class Transaction {
  final int orderId;
  final int merchantId;
  final int customerId;
  final String timestamp;
  final List<Items> items;
  final int totalPointPrice;
  final double totalRegularPrice;
  final double totalGratuity;
  final bool inAppPayments;
  final String status;
  final int employeeId;
  final String pointOfSale;
  final double totalServiceFee;
  final double totalTax;

  Transaction({
    required this.orderId,
    required this.merchantId,
    required this.customerId,
    required this.timestamp,
    required this.items,
    required this.totalPointPrice,
    required this.totalRegularPrice,
    required this.totalGratuity,
    required this.inAppPayments,
    required this.status,
    required this.employeeId,
    required this.pointOfSale,
    required this.totalServiceFee,
    required this.totalTax,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      orderId: json['orderId'] ?? 0,
      merchantId: json['merchantId'] ?? 0,
      customerId: json['customerId'] ?? 0,
      timestamp: json['timestamp'] ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => Items.fromJson(item))
          .toList(),
      totalPointPrice: json['totalPointPrice'] ?? 0,
      totalRegularPrice: (json['totalRegularPrice'] ?? 0).toDouble(),
      totalGratuity: (json['totalGratuity'] ?? 0).toDouble(),
      inAppPayments: json['inAppPayments'] ?? false,
      status: json['status'] ?? '',
      employeeId: json['employeeId'] ?? 0,
      pointOfSale: json['pointOfSale'] ?? '',
      totalServiceFee: (json['totalServiceFee'] ?? 0).toDouble(),
      totalTax: (json['totalTax'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'merchantId': merchantId,
      'customerId': customerId,
      'timestamp': timestamp,
      'items': items.map((item) => item.toJson()).toList(),
      'totalPointPrice': totalPointPrice,
      'totalRegularPrice': totalRegularPrice,
      'totalGratuity': totalGratuity,
      'inAppPayments': inAppPayments,
      'status': status,
      'employeeId': employeeId,
      'pointOfSale': pointOfSale,
      'totalServiceFee': totalServiceFee,
      'totalTax': totalTax,
    };
  }
}

