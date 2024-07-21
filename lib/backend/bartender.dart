import 'package:barzzy_app1/Backend/bar.dart';
import 'package:barzzy_app1/Backend/order.dart';

import 'package:barzzy_app1/Backend/status.dart';

class Bartender {
  Bar bar;
  String name;
  //Image field too

  bool isWorking = false;
  Order? currOrder; //Starts as null
  List<Order> readyOrders = []; // Empty list

  // Constructor initalizes the bar and the name
  Bartender(this.bar, this.name);

  void setIsWorking(bool working) {
    isWorking = working;
  }

  //Bartender wants to claim an order to start preparing
  void claimOrder(int orderNum) {
    Order? claimed = bar.getOrder(orderNum);
    if (claimed != null) {
      currOrder = claimed;
      currOrder?.setStatus(Status.preparing);
    }
  }

  //Bartender wants to make their current Order ready
  void makeReady() {
    currOrder?.setStatus(Status.ready);
    readyOrders.add(currOrder!);
    currOrder = null;
  }
}