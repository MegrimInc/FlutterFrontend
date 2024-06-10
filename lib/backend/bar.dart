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

Drink getDrinkById(String id) {
  return drinks!.firstWhere((drink) => drink.id == id);
}

  

//Filtering Stuff

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Method to separate drinks into one big list of ids
  List<String> getAllDrinkIds() {
    return drinks?.map((drink) => drink.id).toList() ?? [];
  }



List<String> getDrinkIdsByCategory(String category) {
  List<String> drinkIds = [];
  category = category.trim(); // Trim the category

  for (var drink in drinks!) {
    if (drink.type.trim() == category) {
      drinkIds.add(drink.id);
    }
  }

  return drinkIds;
}


List<String> getDrinkIdsBySubcategory(String category, String subcategory) {
  List<String> drinkIds = [];
  category = category.trim();

  for (var drink in drinks!) {
    if (drink.type.trim() == category && drink.ingredients.contains(subcategory)) {
      drinkIds.add(drink.id);
    }
  }

  return drinkIds;
}


Map<String, int> getDrinkCounts() {
  // Initialize counts for each category
  int liquorCount = 0;
  int casualCount = 0;
  int virginCount = 0;

  // Loop through all drinks and increment counts based on type
  for (var drink in drinks!) {
    switch (drink.type) {
      case 'Liquor':
        liquorCount++;
        break;
      case 'Brew':
        casualCount++;
        break;
      case 'Virgin':
        virginCount++;
        break;
      default:
        break;
    }
  }

  // Return a map containing counts for each category
  return {
    'Liquor': liquorCount,
    'Brew': casualCount,
    'Virgin': virginCount,
  };
}



Map<String, Map<String, int>> getSubcategoryDrinkCounts() {
    Map<String, Map<String, int>> subcategoryCounts = {};

    for (var drink in drinks ?? []) {
      String category = drink.type.trim();

      if (!subcategoryCounts.containsKey(category)) {
        subcategoryCounts[category] = {};
      }

      for (var ingredient in drink.ingredients) {
        String subcategory = ingredient.trim();
        if (!subcategoryCounts[category]!.containsKey(subcategory)) {
          subcategoryCounts[category]![subcategory] = 0;
        }
        subcategoryCounts[category]![subcategory] = subcategoryCounts[category]![subcategory]! + 1;
      }
    }

    return subcategoryCounts;
  }





}









