

import 'package:barzzy_app1/Backend/order.dart';
import 'package:barzzy_app1/Backend/orderque.dart';
import 'package:barzzy_app1/Backend/response.dart';
import 'package:barzzy_app1/Backend/user.dart';
import 'package:flutter/material.dart';
import 'drink.dart';

class Bar {
  String? id;
  String? name;
  String? address;
  String? tag;
  String? tagimg;
  String? barimg;
  Map<String, Drink>? drinks;
  OrderQueue orderQ = OrderQueue(); // Manages order operations

  Bar(
      {
      this.id,
      this.name,
      this.address,
      this.tag,
      this.tagimg,
      this.barimg
      }
      );

   void addDrink(Drink drink) {
    drinks ??= <String, Drink>{};
    drinks![drink.id] = drink;
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

   // Method to get a drink object by its ID
  Drink getDrinkById(String id) {
    return drinks![id]!;
  }

  // JSON serialization to support saving and loading bar data
  Map<String, dynamic> toJson() {
    return {
     'id': id,
      'name': name,
      'address': address,
      'tag': tag,
      'tagimg': tagimg,
      'barimg': barimg,
    };
  }

  // Factory constructor for creating an instance from JSON
  factory Bar.fromJson(Map<String, dynamic> json) {
    return Bar(
      id: json['id']?.toString(),
      name: json['name'] as String?,
      address: json['address'] as String?,
      tag: json['tag'] as String?,
      tagimg: json['tagimg'] as String?,
      barimg: json['barimg'] as String?,
    );
  }

  void searchDrinks(String query, User user, String barId) {
    Set<String> filteredIdsSet = {};
    user.addQueryToHistory(barId, query);
    query = query.toLowerCase().replaceAll(' ', '');

    debugPrint('Search query received: $query');

    // nameAndTagMap?.forEach((key, value) {
    //   // Check if the lowercase key contains the lowercase query as a substring
    //   if (key.toLowerCase().contains(query)) {
    //     filteredIdsSet.addAll(value);
    //   }
    // });
    List<String> filteredIds = filteredIdsSet.toList();

    debugPrint(
        'Filtered IDs for query $query: $filteredIds'); // Print the filtered IDs

    if (filteredIds.isEmpty) {
      Response().addNegativeResponse(user, barId);
    } else {
      Response().addPositiveResponse(user, barId);
    }

    user.addSearchQuery(barId, query, filteredIds);
    //user.addQueryToHistory(barId, query);
  }
}
