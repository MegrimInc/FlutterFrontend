/*
import 'dart:convert';
import 'package:barzzy_app1/AuthPages/RegisterPages/verification.dart';
import 'package:barzzy_app1/backend/drink.dart';
import 'package:barzzy_app1/backend/order.dart';
import 'package:http/http.dart' as http;
import 'package:barzzy_app1/AuthPages/RegisterPages/logincache.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrdersPage extends StatefulWidget {
  final Function()? onTap;
  const OrdersPage({super.key, this.onTap});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String barStatus = 'Loading...'; // Default value
  bool autoClaim = false; // Autoclaim switch state
  bool showAll = false; // Toggle for showing all orders

  List<Order> claimedOrders = [
    Order(1, 19, 1, 0.4, ['Coke', 'Pepsi']),
    Order(2, 29, 2, 0.3, ['Sprite', 'Fanta']),
    Order(3, 39, 4, 0.5, ['Water', 'Juice']),
  ];

  List<Order> readyOrders = [
    Order(1, 19, 1, 0.4, ['Test', 'Two']),
    Order(2, 29, 2, 0.3, ['Three', 'Is']),
    Order(3, 39, 4, 0.5, ['This', 'Working']),
  ];

  void reroll() async {
    final loginCacheA = LoginCache(); 
    final url = Uri.parse('https://www.barzzy.site/signup/reroll');
    final requestBody = jsonEncode({
      'email': await loginCacheA.getEmail(),
      'password': await loginCacheA.getPW(),
    });
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );
    if (response.statusCode == 200) {
      print('Request successful');
      if (response.body == "sent email") {
        // Handle success
      } 
    } else {
      print('02Request failed with status: ${response.statusCode}');
      failure();
    }      
  } 

  void failure() {
    showDialog(
      context: context,
      builder: (context) {
        return const AlertDialog(
          backgroundColor: Colors.white,
          title: Center(
            child: Text(
              'Something went wrong. Please try again later.',
              style: TextStyle(color: Color.fromARGB(255, 30, 30, 30), fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  void invalidEmail() {
    showDialog(
      context: context,
      builder: (context) {
        return const AlertDialog(
          backgroundColor: Colors.white,
          title: Center(
            child: Text(
              'Invalid email. Please try again.',
              style: TextStyle(color: Color.fromARGB(255, 30, 30, 30), fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  void invalidCredentialsMessage() {
    showDialog(
      context: context,
      builder: (context) {
        return const AlertDialog(
          backgroundColor: Colors.white,
          title: Center(
            child: Text(
              'Invalid input. Please check your fields.',
              style: TextStyle(color: Color.fromARGB(255, 30, 30, 30), fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchBarStatus();
  }

  Future<void> _fetchBarStatus() async {
    final url = Uri.parse('https://www.barzzy.site/signup/getBarStatus');
    final requestBody = jsonEncode({
      'email': 'placeholder@example.com', // REPLACE
      'password': 'placeholderPassword', // REPLACE
    });
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );
    if (response.statusCode == 200) {
      setState(() {
        barStatus = response.body == 'open' ? 'Close Bar' : 'Open Bar';
      });
    } else {
      setState(() {
        barStatus = 'Error';
      });
    }
  }

  Future<void> _handleLogout() async {
    if (readyOrders.isEmpty && claimedOrders.isEmpty) {
      // Perform logout operation here
      print('Logout action triggered');
      // Simulate logout process (replace with actual logout code)
      final response = await http.post(
        Uri.parse('https://www.barzzy.site/signup/logout'), // Example URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'placeholder@example.com',
          'password': 'placeholderPassword',
        }),
      );

      if (response.statusCode == 200) {
        // Handle successful logout if needed
        print('Logout successful');
      } else {
        _showAlert('Failed to log out. Please try again.', isError: true);
      }
    } else {
      _showAlert('Cannot log out with orders still present.', isError: true);
    }
  }

  void _toggleBarStatus() {
    print('Bar status toggled');
  }

  Future<void> _handleClaim15() async {
    if (claimedOrders.isEmpty) { 
      final url = Uri.parse('https://www.barzzy.site/signup/get15');
      final requestBody = jsonEncode({
        'email': 'placeholder@example.com',
        'password': 'placeholderPassword',
      });
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Order> fetchedOrders = data.map((json) => Order.fromJson(json)).toList();
        fetchedOrders.sort((a, b) => a.orderId.compareTo(b.orderId));
        setState(() {
          claimedOrders = fetchedOrders;
        });
      } else {
        print('Failed to claim orders');
      }
    } else {
      print('Orders list is not empty');
    }
  }

  void _showAlert(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _updateLists() {
    claimedOrders.sort((a, b) => a.orderId.compareTo(b.orderId));
    readyOrders.sort((a, b) => a.orderId.compareTo(b.orderId));
  }

  Future<void> _handleOrderAction(Order order, String action) async {
    final url = action == 'Ready'
        ? Uri.parse('https://www.barzzy.site/signup/ready')
        : Uri.parse('https://www.barzzy.site/signup/return');

    final requestBody = jsonEncode({
      'email': 'placeholder@example.com',
      'password': 'placeholderPassword',
      'orderId': order.orderId, // Use only the orderId
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );

    if (response.statusCode == 200) {
      setState(() {
        if (action == 'Ready') {
          claimedOrders.remove(order);
          readyOrders.add(order);
        } else {
          claimedOrders.remove(order);
        }
        _updateLists();
        _showAlert('Order ${action.toLowerCase()}ed');
      });
    } else {
      _showAlert('Failed to perform action', isError: true);
    }
  }

  Future<void> _handleReadyOrderAction(Order order, String action) async {
    final url = action == 'Delivered'
        ? Uri.parse('https://www.barzzy.site/signup/delivered')
        : Uri.parse('https://www.barzzy.site/signup/cancel');

    final requestBody = jsonEncode({
      'email': 'placeholder@example.com',
      'password': 'placeholderPassword',
      'orderId': order.orderId, // Use only the orderId
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );

    if (response.statusCode == 200) {
      setState(() {
        readyOrders.remove(order);
        _updateLists();
        _showAlert('Order ${action.toLowerCase()}ed');
      });
    } else {
      _showAlert('Failed to ${action.toLowerCase()}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Order> ordersToDisplay;

    if (showAll) {
      ordersToDisplay = [...claimedOrders, ...readyOrders]
        ..sort((a, b) => a.orderId.compareTo(b.orderId));
    } else {
      ordersToDisplay = claimedOrders;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Orders'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  showAll ? 'Show Claimed' : 'Show All',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: showAll,
                  onChanged: (bool value) {
                    setState(() {
                      showAll = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GestureDetector(
              onTap: _handleClaim15,
              child: Container(
                padding: EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Text(
                  'Claim 15',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GestureDetector(
              onTap: _handleLogout, // Updated to call _handleLogout
              child: Container(
                padding: EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.red, // Assuming Logout button is red
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GestureDetector(
              onTap: _toggleBarStatus,
              child: Container(
                padding: EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  barStatus,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: ordersToDisplay.length,
        itemBuilder: (context, index) {
          final order = ordersToDisplay[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            color: showAll && readyOrders.contains(order) ? Colors.green[100] : Colors.yellow[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ListTile(
                  title: Text('Order ID: ${order.orderId}'),
                  subtitle: Text('Price: \$${order.price.toStringAsFixed(2)}'),
                  trailing: claimedOrders.contains(order)
                      ? PopupMenuButton<String>(
                          onSelected: (value) {
                            _handleOrderAction(order, value);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'Ready',
                              child: Container(
                                color: Colors.green, // Background color for 'Ready'
                                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                child: Text(
                                  'Ready',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'Return',
                              child: Container(
                                color: Colors.red, // Background color for 'Return'
                                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                child: Text(
                                  'Return',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        )
                      : readyOrders.contains(order)
                          ? PopupMenuButton<String>(
                              onSelected: (value) {
                                _handleReadyOrderAction(order, value);
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem<String>(
                                  value: 'Delivered',
                                  child: Container(
                                    color: Colors.green, // Background color for 'Delivered'
                                    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                    child: Text(
                                      'Delivered',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'Cancel',
                                  child: Container(
                                    color: Colors.red, // Background color for 'Cancel'
                                    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : null,
                ),
                Column(
                  children: order.name.map((drinkName) {
                    return ListTile(
                      title: Text(drinkName),
                      contentPadding: EdgeInsets.only(left: 16.0, right: 16.0),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

*/