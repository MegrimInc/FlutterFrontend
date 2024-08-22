import 'dart:async'; // Import the async package for Timer
import 'dart:convert'; //TODO check bar is active 
import 'dart:io';

import 'package:barzzy_app1/Terminal/ordersv2-0.dart';
import 'package:flutter/material.dart';
import 'package:barzzy_app1/backend/order.dart';

class OrdersPage extends StatefulWidget {
  final String bartenderID; // Bartender ID parameter
  final int barID;

  const OrdersPage({Key? key, required this.bartenderID, required this.barID, }) : super(key: key);

  

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Order> allOrders = [
    Order(1, 101, 202,  ['Coke', 'Pepsi', 'one', 'two', 'three', 'four'], 'unclaimed', '', DateTime.now().millisecondsSinceEpoch + 100),
    Order(2, 102, 203,  ['Sprite', 'Fanta'], 'unclaimed', '', DateTime.now().millisecondsSinceEpoch - 200000),
    Order(3, 103, 204,  ['Water', 'Juice'], 'claimed', 'Z', DateTime.now().millisecondsSinceEpoch - 300000),
    Order(4, 201, 205,  ['Test', 'Two'], 'unclaimed', '', DateTime.now().millisecondsSinceEpoch - 400000),
    Order(5, 202, 206, ['Three', 'Is'], 'claimed', 'test', DateTime.now().millisecondsSinceEpoch - 800000),
    Order(6, 203, 207, ['This', 'Working'], 'ready', 'test', DateTime.now().millisecondsSinceEpoch),
  ];

  List<Order> displayList = [];

//TESTING VARIABLE
  bool testing = true;

  bool filterUnique = true;
  bool filterHideReady = false;
  bool priorityFilterShowReady = false;
  int bartenderCount = 1; // Number of bartenders
  int bartenderNumber = 2; // Set to bartenderCount + 1
  bool disabledTerminal = false; // Tracks if terminal is disabled
  bool barOpenStatus = true; // Track if bar is open or closed
  WebSocket? socket;

  Timer? _timer;
  WebSocket? websocket;

  @override
  void initState() {
    super.initState();


  initWebsocket();

    // Initialize filters and bartender number
    filterUnique = true;
    filterHideReady = true;
    bartenderNumber = 0;
    bartenderCount = 1;
    
    _updateLists();

    // Start a timer to update the list every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateLists();
    });


  // Listen for the response from the server
  socket?.listen((event) {

debugPrint('Received: $event');

        // Handle the response from the server
        if (event.contains("Initialization successful")) {
          _showAlertDialog(context, "Success!", "Logged in as ${widget.bartenderID}");
          //TODO Auto-Refresh
          
        } else if (event.contains("Initialization failed")) {
          // Show an alert dialog if the response is unsuccessful
          _showAlertDialog(context, "Error", "Failed to initialize: $event");
            Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => BartenderIDScreen()),
            (Route<dynamic> route) => false, // Remove all previous routes
          );
        }

  // Parse the JSON response from the server
  final Map<String, dynamic> response = jsonDecode(event);



  // Check which key is present in the response and handle accordingly
  switch (response.keys.first) {
    case 'error':
      // Use _showErrorSnackbar to display the error message
      _showErrorSnackbar(response['error']);
      break;

    case 'terminate':
      disabledTerminal = true;
      _showErrorSnackbar("Connection terminated by the server: new connection inbound");
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => BartenderIDScreen()),
        (Route<dynamic> route) => false, // Remove all previous routes
      );
        if (socket != null) {
        socket!.close(); // Close the WebSocket connection
        socket = null; // Set the WebSocket reference to null
  }

      break;

    case 'orders':
      final List<dynamic> ordersJson = response['orders'];
      
      // Convert JSON to Order objects and update allOrders
      final incomingOrders = ordersJson.map((json) => Order.fromJson(json)).toList();
      for (Order incomingOrder in incomingOrders) {
        // Check if the order exists in allOrders
        int index = allOrders.indexWhere((order) => order.userId == incomingOrder.userId);
        
        if (index != -1) {
          // If it exists, replace the old order
          allOrders[index] = incomingOrder;
          if( allOrders[index].status == 'delivered' || allOrders[index].status == 'canceled') allOrders.remove(allOrders[index]);
        } else {
          // If it doesn't exist, add the new order to allOrders
          if( allOrders[index].status != 'delivered' && allOrders[index].status != 'canceled') allOrders.add(incomingOrder);
                    
        }
      }
      setState(() {
        // Update the displayList based on the new allOrders
        _updateLists();
      });
      break;

    case 'barStatus':
       // Update barOpenStatus and refresh UI
        setState(() {
          barOpenStatus = response['barStatus'];
        });
        break;

    case 'disableTerminal':
        _disableTerminal();
        break;

    case 'updateTerminal':
        // Update local values and refresh UI
        setState(() {
          bartenderCount = response['bartenderCount'];
          bartenderNumber = response['bartenderNumber'];
        });
        break;

    default:
      print("Unknown key received in WebSocket message: ${response.keys.first}");
  }
},
    onError: (error) {
      // Handle WebSocket errors
      if(!disabledTerminal) _handleWebSocketError(error);
    },
    onDone: () {

debugPrint('WebSocket connection closed');
      if(!disabledTerminal) _handleWebSocketTermination(); 
    },
    cancelOnError: false, // Optionally, cancel the listener on error
  );
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

void _updateLists() {
  // Sort `allOrders` by timestamp, older orders first
  allOrders.sort((a, b) => a.timestamp.compareTo(b.timestamp));

  List<Order> claimedByBartender = [];
  List<Order> notClaimedByBartender = [];

  // Separate orders based on whether they are claimed by the bartender
  for (var order in allOrders) {
    if (widget.bartenderID == order.claimer && order.status != 'claimed' && order.status != 'delivered') {
      claimedByBartender.add(order);
    } else if (order.status != 'claimed' && order.status != 'delivered') {
      notClaimedByBartender.add(order);
    }
  }

  // Combine the lists: orders claimed by bartender first, then the rest
  displayList = claimedByBartender + notClaimedByBartender;

  if (priorityFilterShowReady) {
    displayList = displayList.where((order) => (order.userId % bartenderCount) == bartenderNumber).toList();
    displayList = displayList.where((order) => order.status == 'ready').toList();
  } else {
    if (filterUnique) {
      displayList = displayList.where((order) =>
        order.claimer == widget.bartenderID || 
        (order.claimer.isEmpty && (order.userId % bartenderCount) == bartenderNumber)
      ).toList();      
    }

    if (filterHideReady) {
      displayList = displayList.where((order) => order.status != 'ready').toList();
    }
  }

  // Check if terminal is disabled and no orders are claimed by the bartender
  if (disabledTerminal && !allOrders.any((order) => order.claimer == widget.bartenderID)) {
    
      socket?.add(
      json.encode({
        'action': 'dispose',
        'barID': widget.barID,
      }),
      );

     if (socket != null) {
        socket!.close(); // Close the WebSocket connection
        socket = null; // Set the WebSocket reference to null
     }

     
      Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => BartenderIDScreen()),
      (Route<dynamic> route) => false, // Remove all previous routes
    );


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

    // Refresh the list after disabling the terminal
    _updateLists();

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
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Row(
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
                const Text('Your Orders Only'),
              ],
            );
          },
        ),
      ),
      PopupMenuItem(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Row(
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
            );
          },
        ),
      ),
      PopupMenuItem(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Row(
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
                const Text('[Override] Ready-Only'),
              ],
            );
          },
        ),
      ),
    ],
  );
}


void _toggleBarStatus() {
  if (!barOpenStatus && allOrders.isNotEmpty) {
    // If the bar is currently closed and there are still orders, show a Snackbar and do not open the bar.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Cannot re-open the bar while there are unfulfilled orders!"),
        duration: Duration(seconds: 3),
      ),
    );
    return; // Exit the function without changing the barOpenStatus
  }
debugPrint(barOpenStatus ? 'close' : 'open' ' sent');
  socket?.add(
  json.encode({
    'action': barOpenStatus ? 'close' : 'open',
    'barID': widget.barID,
  }),
  );

  debugPrint('Bar status toggled. New status: ${barOpenStatus ? "Open" : "Closed"}');
}

void _showErrorSnackbar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ),
  );
}


void _refresh() {
  allOrders.clear();
  displayList.clear();
  
  // Send a 'refresh' action to the server via WebSocket
  debugPrint("refresh sent");
  socket?.add(
    jsonEncode({
      'action': 'refresh',
      'barID': widget.barID,
    }),
  );
  setState((){});
}

  void _executeFunctionForUnclaimed(Order order) {
    // Construct the message
    final claimRequest = {
      'action': 'claim',
      'bartenderID': widget.bartenderID,
      'orderID': order.userId,
      'barID': order.barId,
    };

    // Send the message via WebSocket
    debugPrint("claimRequest");
    socket?.add(jsonEncode(claimRequest));
    debugPrint("attempting claim");
  }

void _executeFunctionForClaimed(Order order) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          'Bar #${order.barId}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), // Larger title
        ),
        content: Container(
          height: 200, // Increase the height of the dialog
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Spacer(), // Space at the top
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      debugPrint("unclaim");
                      socket?.add(
                        json.encode({
                          'action': 'unclaim',
                          'bartenderID': widget.bartenderID,
                          'orderID': order.userId,
                          'barID': order.barId,
                        }),
                      );
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 32), // Double the vertical padding
                    ),
                    child: const Text(
                      'Unclaim',
                      style: TextStyle(fontSize: 20, color: Colors.white), // Larger text
                    ),
                  ),
                  const SizedBox(width: 20), // Add horizontal space between buttons
                  ElevatedButton(
                    onPressed: () {
                      debugPrint("ready");
                      socket?.add(
                        json.encode({
                          'action': 'ready',
                          'bartenderID': widget.bartenderID,
                          'orderID': order.userId,    
                          'barID': widget.barID,
                        }),
                      );
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 32), // Double the vertical padding
                    ),
                    child: const Text(
                      'Ready',
                      style: TextStyle(fontSize: 20, color: Colors.white), // Larger text
                    ),
                  ),
                ],
              ),
              const Spacer(), // Space at the bottom
            ],
          ),
        ),
      );
    },
  );
}



void _executeFunctionForClaimedAndReady(Order order) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          'Order #${order.userId}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), // Larger title
        ),
        content: Container(
          height: 200, // Increase the height of the dialog
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Spacer(), // Space at the top
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      debugPrint("Cancel");
                      socket?.add(
                        json.encode({
                          'action': 'cancel',
                          'bartenderID': widget.bartenderID,
                          'orderID': order.userId,
                          'barID': widget.barID,
                        }),
                      );
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 32), // Double the vertical padding
                    ),
                    child: const Text(
                      'Cancelled',
                      style: TextStyle(fontSize: 20, color: Colors.white), // Larger text
                    ),
                  ),
                  const SizedBox(width: 30), // Increased horizontal space between buttons
                  ElevatedButton(
                    onPressed: () {
                      debugPrint("deliver");
                      socket?.add(
                        json.encode({
                          'action': 'deliver',
                          'bartenderID': widget.bartenderID,
                          'orderID': order.userId,
                          'barID': widget.barID,
                        }),
                      );
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 32), // Double the vertical padding
                    ),
                    child: const Text(
                      'Delivered',
                      style: TextStyle(fontSize: 20, color: Colors.white), // Larger text
                    ),
                  ),
                ],
              ),
              const Spacer(), // Space at the bottom
            ],
          ),
        ),
      );
    },
  );
}







  void _onOrderTap(Order order) {
    if (order.claimer.isEmpty) {
      _executeFunctionForUnclaimed(order);
    } else if (order.claimer == widget.bartenderID) {
      if (order.status == 'ready') {
        _executeFunctionForClaimedAndReady(order);
      } else {
        _executeFunctionForClaimed(order);
      }
    }
  }

  Color _getOrderTintColor(Order order) {
    final ageInSeconds = order.getAge();
    
    // Debug print to show age and orderId
    debugPrint('Order ID: ${order.userId}, Age: $ageInSeconds seconds');
    if (order.claimer != '' && order.claimer != widget.bartenderID ) {
      return Colors.grey[700]!;
    }
    
    if (order.status == 'ready') return Colors.green;
    if (ageInSeconds <= 180) return Colors.yellow[200]!; // 0-3 minutes old
    if (ageInSeconds <= 300) return Colors.orange[200]!; // 3-5 minutes old
    if (ageInSeconds <= 600) return Colors.orange[500]!; // 5-10 minutes old
    return Colors.red[700]!; // Over 10 minutes old
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: const Text('Orders'),
        ),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: () {
                  debugPrint("disable");
                      socket?.add(
                        json.encode({
                          'action': 'disableTerminal',
                          'bartenderID': widget.bartenderID,
                          'barID': widget.barID
                        }),
                      );
                } 
              ),
            ),
            // Removed the IconButton for Logout
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
              _refresh();
            },
          ),
          GestureDetector(
            onLongPress: _toggleBarStatus, // Handle long press
            child: Container(
              color: barOpenStatus ? Colors.red : Colors.green,
              child: Center(
                child: Text(
                  barOpenStatus ? "[HOLD] Close Bar" : "[HOlD] Open Bar",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16), // Add space between the last action and the edge
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            itemCount: displayList.length,
            itemBuilder: (context, index) {
              final order = displayList[index];
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
                              Text(
                                '#${order.userId}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      offset: Offset(1.0, 1.0),
                                      blurRadius: 1.0,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${order.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      offset: Offset(1.0, 1.0),
                                      blurRadius: 1.0,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '@${order.userId}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      offset: Offset(1.0, 1.0),
                                      blurRadius: 1.0,
                                    ),
                                  ],
                                ),
                              ),
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
                                title: Text(
                                  drinkName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        offset: Offset(1.0, 1.0),
                                        blurRadius: 1.0,
                                      ),
                                    ],
                                  ),
                                ),
                                contentPadding: EdgeInsets.zero,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      // Container for claimer text box
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity, // Full width of the available space
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black, width: 2), // Static black border
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Center(
                                  child: Text(
                                    order.claimer,
                                    style: TextStyle(
                                      fontSize: 24, // Increased font size
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black,
                                          offset: Offset(1.0, 1.0),
                                          blurRadius: 1.0,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8), // Space between text box and timer
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.timer, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDuration(order.getAge()),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black,
                                            offset: Offset(1.0, 1.0),
                                            blurRadius: 1.0,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bartender ID: ${widget.barID}//${widget.bartenderID}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Active Terminals: $bartenderCount',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  backgroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final Duration duration = Duration(seconds: seconds);
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
  
  
  
  void _handleWebSocketError(error) { 
  }
  
  void _handleWebSocketTermination() {

  }


void _showAlertDialog(BuildContext context, String title, String content) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

  void initWebsocket() async {
       try {
      // Attempt to open a WebSocket connection
      final url = 'wss://www.barzzy.site/ws/bartenders';

      socket = await WebSocket.connect(url);
      
      debugPrint('Connected to WebSocket at $url');

      // Send a message to initialize the bartender session
      final Map<String, dynamic> bartenderLogin = {'action': 'initialize', 'barID': widget.barID, 'bartenderID': widget.bartenderID};
      debugPrint("login");
      socket?.add(jsonEncode(bartenderLogin));
      




    } catch (e) {
      // Handle the error
      debugPrint('Failed to connect to WebSocket: $e');
      _showAlertDialog(context, "Connection Error", "Could not connect to the server. Please try again.");
    }
  }

}

