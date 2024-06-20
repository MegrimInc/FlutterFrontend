import 'package:barzzy_app1/Backend/bartender.dart';
import 'package:barzzy_app1/Backend/order.dart';
import 'package:barzzy_app1/Backend/orderque.dart';
import 'package:barzzy_app1/Backend/user.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'drink.dart';

class Bar {
  List<Drink>? drinks;
  String? name, address;
  String? tag;
  Map<String, List<String>>? nameAndTagMap;
  final Uuid _uuid = const Uuid();

  List<Bartender>? bartenders;
  OrderQueue orderQ = OrderQueue(); // Manages order operations

  Bar({this.drinks, this.name, this.address, this.tag, this.nameAndTagMap});

  void addDrink(Drink drink) {
    drinks ??= [];
    drink.id = _uuid.v4(); // Assign a unique ID to the drink
    drinks!.add(drink);
    //debugPrint('Adding drink: ${drink.name} with ID: ${drink.id}');
    updateNameAndTagMap(drink);
  }

//   void updateNameAndTagMap(Drink drink) {
//      nameAndTagMap ??= {};
//     Set<String> uniqueDrinkIds = {};

//     try {
//       // Extract and process the name
//       String name = drink.name.toLowerCase().replaceAll(' ', '');

//       // Extract and process the ingredients as tags
//       for (var ingredient in drink.ingredients) {
//         try {
//           String tag = ingredient.toLowerCase().replaceAll(' ', '');

//           if (!uniqueDrinkIds.contains(drink.id)) {
//             nameAndTagMap?.putIfAbsent(tag, () => []).add(drink.id);
//             //debugPrint('Added drink ID ${drink.id} under tag $tag');
//             uniqueDrinkIds.add(drink.id); // Add the drink ID to the set
//           }
//         } catch (e) {
//           debugPrint('Error processing tag for drink ${drink.name}: $e');
//         }
//       }

//       nameAndTagMap?.putIfAbsent(name, () => []).add(drink.id);
//       //debugPrint('Inlcuded drink ID: ${drink.id} under tag $name');
//       uniqueDrinkIds.add(drink.id);
//     } catch (e) {
//       debugPrint('Error processing drink ${drink.name}: $e');
//     }

//     // debugPrintVodkaTagDrinkIds();

//     // Remove duplicates
//     nameAndTagMap?.forEach((key, value) {
//       nameAndTagMap?[key] = value.toSet().toList();
//     });

//     // Debug statement to show the final nameAndTagMap
//     //debugPrint('Final nameAndTagMap: $nameAndTagMap');
//   }

//   //GETTER METHODS

//  Map<String, List<String>>? getNameAndTagMap() {
//   return nameAndTagMap;
// }

  void updateNameAndTagMap(Drink drink) {
  nameAndTagMap ??= {};
  
  try {
    // Extract and process the name
    String name = drink.name.toLowerCase().replaceAll(' ', '');

    // Extract and process the ingredients as tags
    for (var ingredient in drink.ingredients) {
      try {
        String tag = ingredient.toLowerCase().replaceAll(' ', '');
        
        // Ensure no duplicates
        if (nameAndTagMap?.containsKey(tag) ?? false) {
          if (!nameAndTagMap![tag]!.contains(drink.id)) {
            nameAndTagMap?[tag]?.add(drink.id);
          }
        } else {
          nameAndTagMap?.putIfAbsent(tag, () => []).add(drink.id);
        }

        // debugPrint('Added drink ID ${drink.id} under tag $tag');
      } catch (e) {
        debugPrint('Error processing tag for drink ${drink.name}: $e');
      }
    }

    // Ensure no duplicates
    if (nameAndTagMap?.containsKey(name) ?? false) {
      if (!nameAndTagMap![name]!.contains(drink.id)) {
        nameAndTagMap?[name]?.add(drink.id);
      }
    } else {
      nameAndTagMap?.putIfAbsent(name, () => []).add(drink.id);
    }

    // debugPrint('Included drink ID: ${drink.id} under tag $name');
  } catch (e) {
    debugPrint('Error processing drink ${drink.name}: $e');
  }

  // No need to remove duplicates, as duplicates are already prevented

  // Debug statement to show the final nameAndTagMap
  // debugPrint('Final nameAndTagMap: $nameAndTagMap');
}


  

     //GETTER METHODS

  Map<String, List<String>>? getNameAndTagMap() {
      return nameAndTagMap;
    }

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
      'tag': tag,
      'nameAndTagMap': nameAndTagMap?.map((key, value) => MapEntry(key, value)),
    };
  }

  // Factory constructor for creating an instance from JSON
  factory Bar.fromJson(Map<String, dynamic> json) {
    var drinksList = json['drinks'] as List?;
    List<Drink>? drinks =
        drinksList?.map((item) => Drink.fromJson(item)).toList();
    // Extract nameAndTagMap from JSON
    var nameAndTagMapJson = json['nameAndTagMap'] as Map<String, dynamic>?;
    Map<String, List<String>>? nameAndTagMap;
    if (nameAndTagMapJson != null) {
      nameAndTagMap = nameAndTagMapJson.map((key, value) {
        if (value is List) {
          return MapEntry(key, value.cast<String>());
        }
        return MapEntry(key, []);
      });
    }

    return Bar(
      drinks: drinks,
      name: json['name'] as String?,
      address: json['address'] as String?,
      tag: json['tag'] as String?,
      nameAndTagMap: nameAndTagMap,
    );
  }

  Drink getDrinkById(String id) {
    return drinks!.firstWhere((drink) => drink.id == id);
  }

  void searchDrinks(String query, User user, String barId) {
    Set<String> filteredIdsSet = {};
   // List<String> filteredIds = [];
    query = query.toLowerCase().replaceAll(' ', '');

    debugPrint('Search query received: $query');

    nameAndTagMap?.forEach((key, value) {
      // Check if the lowercase key contains the lowercase query as a substring
      if (key.toLowerCase().contains(query)) {
        filteredIdsSet.addAll(value);
      }
    });
    List<String> filteredIds = filteredIdsSet.toList();

    debugPrint(
        'Filtered IDs for query $query: $filteredIds'); // Print the filtered IDs

    user.addSearchQuery(barId, query, filteredIds);
  }
}
