// ignore_for_file: prefer_initializing_formals

import 'package:barzzy_app1/Backend/bar.dart';
import 'package:barzzy_app1/Backend/drink.dart';


import 'status.dart';
class Order{
  Bar? bar;
  List<Drink>? drinks;
  double? price;
  int? orderNumber;
  DateTime date = DateTime.now();
  String? customer;
  Status status = Status.unclaimed;

  // Order({this.bar, this.drinks, this.price, this.customer}) {
  //   if (bar != null) {
  //     // Add this order to the queue of orders for that particular bar
  //     orderNumber = bar!.placeOrder(this);
  //   }
  // }


    //Getter methods
    Bar? getBar()
    {
      return bar;
    }

    List<Drink>? getDrink()
    {
      return drinks;
    }

    double? getPrice()
    {
      return price;
    }

    int? getOrderNumber()
    {
      return orderNumber;
    }

    Status getStatus()
    {
      return status;
    }

    DateTime getDateTime()
    {
      return date;
    }

    void setStatus(Status status)
    {
      this.status = status;
    }

    void displayOrderOnPage()
    {
      //Code for displaying the contents of an order
      //once bartender clicks on it.  I'm not sure how this
      //works but I think the display method would go here. -ss
    }

    void displayOrderasList()
    {
      //Intended to display order on the Bartenders tablet
      //as part of a list of multiple other orders. This will
      //be the screen when they can click on an order and claim it.
    }
  }