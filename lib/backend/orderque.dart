import 'dart:collection';
import 'package:barzzy_app1/Backend/status.dart';
import 'package:barzzy_app1/Backend/order.dart';

/// The OrderQueue class stores the orders to connect
/// with the restaurant's front end.  Orders are stored
/// in a HashMap, which is a collection of key value
/// pairs.
class OrderQueue {
  //Orders are accesible by order number (the key)
  HashMap<int, Order> orderMap;
  int currOrderNum = 0;

  OrderQueue() : orderMap = HashMap<int, Order>();

  //Adds a new Order to the orderMap with key
  //currOrderNum + 1
  int placeOrder(Order order) {
    currOrderNum++;
    orderMap[currOrderNum] = order;
    return currOrderNum;
  }

  //Cancels an order from the map by setting its status
  //to Status.cancelled
  void cancelOrder(int orderNum) {
    Order? toCancel = orderMap[orderNum];
    {
      if (toCancel != null) {
        toCancel.setStatus(Status.cancelled);
      }
    }
  }

  Order? getOrder(int orderNum) {
    return orderMap[orderNum];
  }

  int getTotalOrders() {
    return currOrderNum;
  }

  // Figure out live updating of displaying orders
  //In other words, we don't want everything to redisplay
  //when we have a new order.  We want the new order to simply
  //be displayed at the bottom
  displayOrdersAsList() {
    //Since first order number will be 1
    for (int i = 1; i < currOrderNum; i++) {
      Order? toDisplay = orderMap[i];
      //Display the order if its not null or cancelled
      if (toDisplay != null && toDisplay.getStatus() != Status.cancelled) {
        toDisplay.displayOrderasList();
      }
    }
  }
}
