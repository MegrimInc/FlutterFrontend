// ignore_for_file: prefer_initializing_formals


import 'dart:ffi';

import 'package:barzzy_app1/Backend/drink.dart';

import 'status.dart';

class Order {
  int barId;
  int orderId;
  Int userId;
  double price;
  
 

  Order(this.barId, this.orderId, this.userId, this.price, );
 

  Status status = Status.unclaimed;

  // Order({this.bar, this.drinks, this.price, this.customer}) {
  //   if (bar != null) {
  //     // Add this order to the queue of orders for that particular bar
  //     orderNumber = bar!.placeOrder(this);
  //   }
  // }

  //Getter methods


  

  double? getPrice() {
    return price;
  }

 

  Status getStatus() {
    return status;
  }

 
  void setStatus(Status status) {
    this.status = status;
  }

  void displayOrderOnPage() {
    //Code for displaying the contents of an order
    //once bartender clicks on it.  I'm not sure how this
    //works but I think the display method would go here. -ss
  }

  void displayOrderasList() {
    //Intended to display order on the Bartenders tablet
    //as part of a list of multiple other orders. This will
    //be the screen when they can click on an order and claim it.
  }
}
