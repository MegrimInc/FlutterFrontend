// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:barzzy_app1/backend/order.dart';

class OrdersPage extends StatefulWidget {
  final String bartenderID; // Bartender ID parameter

  const OrdersPage({super.key, required this.bartenderID});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Order> allOrders = [
    Order(1, 101, 202, 19.0, ['Coke', 'Pepsi'], 'claimed', 'Bartender A', DateTime.now().millisecondsSinceEpoch - 5000),
    Order(2, 102, 203, 29.0, ['Sprite', 'Fanta'], 'claimed', 'Bartender B', DateTime.now().millisecondsSinceEpoch - 10000),
    Order(3, 103, 204, 39.0, ['Water', 'Juice'], 'claimed', 'Bartender C', DateTime.now().millisecondsSinceEpoch - 15000),
    Order(4, 201, 205, 19.0, ['Test', 'Two'], 'ready', 'Bartender D', DateTime.now().millisecondsSinceEpoch - 20000),
    Order(5, 202, 206, 29.0, ['Three', 'Is'], 'ready', 'Bartender E', DateTime.now().millisecondsSinceEpoch - 25000),
    Order(6, 203, 207, 39.0, ['This', 'Working'], 'ready', 'Bartender F', DateTime.now().millisecondsSinceEpoch - 30000),
  ];

  List<Order> displayList = [];

  bool filterUnique = true;
  bool filterHideReady = false;
  bool priorityFilterShowReady = false;
  int bartenderCount = 1; // Number of bartenders
  int bartenderNumber = 2; // Set to bartenderCount + 1
  bool disabledTerminal = false; // Tracks if terminal is disabled
  bool barOpenStatus = false; // Track if bar is open or closed

  void _updateLists() {
    // Sort `allOrders` by timestamp, older orders first
    allOrders.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    List<Order> claimedByBartender = [];
    List<Order> notClaimedByBartender = [];

    // Separate orders based on whether they are claimed by the bartender
    for (var order in allOrders) {
      if (widget.bartenderID == order.claimer) {
        claimedByBartender.add(order);
      } else {
        notClaimedByBartender.add(order);
      }
    }

    // Combine the lists: orders claimed by bartender first, then the rest
    displayList = claimedByBartender + notClaimedByBartender;

    if (priorityFilterShowReady) {
      displayList = displayList.where((order) => (order.orderId % bartenderCount) == bartenderNumber).toList();
      displayList = displayList.where((order) => order.orderState == 'ready').toList();
    } else {
      if (filterUnique) {
        displayList = displayList.where((order) =>
          order.claimer == widget.bartenderID || 
          (order.claimer.isEmpty && (order.orderId % bartenderCount) == bartenderNumber)
        ).toList();      
      }

      if (filterHideReady) {
        displayList = displayList.where((order) => order.orderState != 'ready').toList();
      }
    }

    // Update state to refresh the UI
    setState(() {});
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      barrierDismissible: true, // Allow dismiss by tapping outside the dialog
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 3), () {
          Navigator.of(context).pop(true);
        });
        return AlertDialog(
          title: const Text('Alert'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  void _disableTerminal() {
    setState(() {
      bartenderNumber = bartenderCount;
      filterUnique = true;
      filterHideReady = false;
      priorityFilterShowReady = false;
      disabledTerminal = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'The terminal is no longer accepting new orders. Once all claimed orders are marked as Delivered, the terminal will automatically exit this screen.',
          style: TextStyle(fontSize: 16),
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 100),
        padding: const EdgeInsets.all(16),
        backgroundColor: Colors.blueGrey[800],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _logout() {
    if (allOrders.any((order) => order.claimer == widget.bartenderID)) {
      _showAlert('You still have claimed orders!');
    } else {
      // Perform logout functionality
      debugPrint('Logout function called');
    }
  }

  void _showFilterMenu() {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 150,
        kToolbarHeight,
        0.0,
        0.0,
      ),
      items: [
        PopupMenuItem(
          child: Row(
            children: [
              Checkbox(
                value: filterUnique,
                onChanged: (bool? value) {
                  setState(() {
                    filterUnique = value ?? false;
                    _updateLists(); // Apply filters when changed
                  });
                },
              ),
              const Text('Unique Orders'),
            ],
          ),
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Checkbox(
                value: filterHideReady,
                onChanged: (bool? value) {
                  setState(() {
                    filterHideReady = value ?? false;
                    _updateLists(); // Apply filters when changed
                  });
                },
              ),
              const Text('Hide Ready Orders'),
            ],
          ),
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Checkbox(
                value: priorityFilterShowReady,
                onChanged: (bool? value) {
                  setState(() {
                    priorityFilterShowReady = value ?? false;
                    _updateLists(); // Apply filters when changed
                  });
                },
              ),
              const Text('[Override] Show Ready Orders Only'),
            ],
          ),
        ),
      ],
    );
  }

  void _showRedistributeDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final TextEditingController bartenderIdController = TextEditingController();

        return AlertDialog(
          title: const Text('Redistribute Other Bartender'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bartenderIdController,
                decoration: const InputDecoration(
                  labelText: 'Other Bartender ID',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Placeholder logic for submit button
              },
              onLongPress: () {
                // Logic for long press to submit
                // Placeholder for submit button long press
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  // Placeholder functions
  void _executeFunctionForUnclaimed() {
    debugPrint('Placeholder function executed for unclaimed order');
  }

  void _executeFunctionForReady() {
    debugPrint('Placeholder function executed for ready order');
  }

  void _executeFunctionForClaimedAndReady() {
    debugPrint('Placeholder function executed for claimed and ready order');
  }

  void _onOrderTap(Order order) {
    if (order.claimer.isEmpty) {
      _executeFunctionForUnclaimed();
    } else if (order.claimer == widget.bartenderID) {
      if (order.orderState == 'ready') {
        _executeFunctionForClaimedAndReady();
      } else {
        _executeFunctionForReady();
      }
    }
  }

  Color _getOrderTintColor(Order order) {
    final ageInSeconds = order.getAge();
    if (order.orderState == 'ready') return Colors.green;
    if (ageInSeconds <= 180) return Colors.white; // 0-3 minutes old
    if (ageInSeconds <= 300) return Colors.yellow[100]!; // 3-5 minutes old
    if (ageInSeconds <= 600) return Colors.orange[100]!; // 5-10 minutes old
    return Colors.red[100]!; // Over 10 minutes old
  }

  Color _getBorderColor(Order order) {
    switch (order.orderState) {
      case 'ready':
        return widget.bartenderID == order.claimer ? Colors.green : Colors.orange;
      case '':
        return Colors.yellow;
      case 'claimed':
        return widget.bartenderID == order.claimer ? Colors.lightBlueAccent : Colors.red;
      default:
        return Colors.grey; // Default border color if the state is unknown
    }
  }

  void _toggleBarStatus() {
    setState(() {
      barOpenStatus = !barOpenStatus;
    }); // ONLY CHANGE BASED ON HTTP
    
    debugPrint('Bar status toggled. New status: ${barOpenStatus ? "Open" : "Closed"}');();
  }


  @override
  void initState() {
    super.initState();
    // GET allOrders
    // Initialize filters and bartender number
    filterUnique = true;
    filterHideReady = false;
    _updateLists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: _disableTerminal,
            ),
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: _logout,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterMenu,
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            color: Colors.red,
            onPressed: () {
              _showRedistributeDialog();
            },
          ),
          GestureDetector(
            onLongPress: _toggleBarStatus, // Handle long press
            child: Container(
              color: barOpenStatus ? Colors.red : Colors.green,
              child: Center(
                child: Text(
                  barOpenStatus ? "Close Bar" : "Open Bar",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            itemCount: displayList.length,
            itemBuilder: (context, index) {
              final order = displayList[index];
              final borderColor = _getBorderColor(order);
              final tintColor = _getOrderTintColor(order);

              return InkWell(
                onTap: () => _onOrderTap(order),
                child: Card(
                  margin: const EdgeInsets.all(8.0),
                  color: tintColor,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Color(0xFFFFD700), width: 2), // Gold border using hex color
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('#${order.orderId}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('\$${order.price.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('@${order.userId}',
                                  style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: order.name.map((drinkName) {
                              return ListTile(
                                title: Text(drinkName),
                                contentPadding: EdgeInsets.zero,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      Container(
                        width: 100, // Adjust width as needed
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor, width: 2),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Center(
                          child: Text(order.claimer,
                              style: TextStyle(fontSize: 16, color: borderColor)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 16.0,
            left: 16.0,
            child: Text(
              'Bartender ID: ${widget.bartenderID}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}