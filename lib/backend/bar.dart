import 'package:barzzy_app1/Backend/bartender.dart';
import 'package:barzzy_app1/Backend/order.dart';
import 'package:barzzy_app1/Backend/orderque.dart';
import 'package:uuid/uuid.dart';
import 'drink.dart';

class Bar {
  List<Drink>? drinks;
  String? name, address;
  String? tag;
  final Uuid _uuid = const Uuid();

  List<Bartender>? bartenders;
  OrderQueue orderQ = OrderQueue(); // Manages order operations

  Bar({this.drinks, this.name, this.address, this.tag});

  void addDrink(Drink drink) {
    drinks ??= [];
    drink.id = _uuid.v4(); // Assign a unique ID to the drink
    drinks!.add(drink);
  }


  //GETTER METHODS

  String? getName() {
    return name;
  }

  OrderQueue getOrderQueue() {
    return orderQ;
  }

  Order? getOrder(int orderNum) {
    return orderQ.getOrder(orderNum);
  }

  int placeOrder(Order order) {
    return orderQ.placeOrder(order);
  }

  int getTotalOrders() {
    return orderQ.getTotalOrders();
  }

  void displayOrdersAsList() {
    orderQ.displayOrdersAsList();
  }

  String? gettag() {
    return tag;
  }

  // JSON serialization to support saving and loading bar data
  Map<String, dynamic> toJson() {
    return {
      'drinks': drinks?.map((d) => d.toJson()).toList(),
      'name': name,
      'address': address,
      'tag': tag
    };
  }

  // Factory constructor for creating an instance from JSON
  factory Bar.fromJson(Map<String, dynamic> json) {
    var drinksList = json['drinks'] as List?;
    List<Drink>? drinks =
        drinksList?.map((item) => Drink.fromJson(item)).toList();
    return Bar(
      drinks: drinks,
      name: json['name'] as String?,
      address: json['address'] as String?,
      tag: json['tag'] as String?,
    );
  }


  Map<String, int> calculateDrinkCounts() {
  Map<String, int> counts = {
    'Liquor': 0,
    'Casual': 0,
    'Virgin': 0,
  };

  for (var drink in drinks!) {
    // Trim the type string to remove any leading or trailing spaces
    String type = drink.type.trim();

    // Increment the count for the corresponding type
    counts.update(type, (value) => value + 1, ifAbsent: () => 1);
  }

  return counts;
}
}
