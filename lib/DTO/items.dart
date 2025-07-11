class Items {
  final int itemId;
  final String itemName;
  final String paymentType;
  final int quantity;

  Items({
    required this.itemId,
    required this.itemName,
    required this.paymentType,
    required this.quantity,
  });

  factory Items.fromJson(Map<String, dynamic> json) {
    return Items(
      itemId: json['itemId'] ?? 0,
      itemName: json['itemName'] ?? '',
      paymentType: json['paymentType'] ?? '',
      quantity: json['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'paymentType': paymentType,
      'quantity': quantity,
    };
  }

  int getItemId() => itemId;
  String getItemName() => itemName;
  String getPaymentType() => paymentType;
  int getQuantity() => quantity;
}