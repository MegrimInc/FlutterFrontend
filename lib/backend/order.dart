// ignore_for_file: prefer_initializing_formals




import 'status.dart';

class Order {
  int barId;
  int orderId;
  int userId;
  double price;

 

  Order(this.barId, this.orderId, this.userId, this.price, );
 

  Status status = Status.unclaimed;

  // Factory constructor for creating an Order from JSON data
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      json['barId'] as int,
      json['orderId'] as int,
      json['userId'] as int, // Changed from Int to int
      (json['price'] as num).toDouble(), // Convert num to double
    );
  }

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