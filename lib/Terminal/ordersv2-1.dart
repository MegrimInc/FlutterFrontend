import 'dart:async'; // Import the async package for Timer
import 'dart:convert'; //TODO check bar is active 
import 'dart:io';

import 'package:barzzy_app1/Terminal/ordersv2-0.dart';
import 'package:barzzy_app1/backend/activeorder.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/gestures.dart';

class OrdersPage extends StatefulWidget {
  final String bartenderID; // Bartender ID parameter
  final int barID;

  const OrdersPage({super.key, required this.bartenderID, required this.barID,});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<CustomerOrder> allOrders = [];

  List<CustomerOrder> displayList = [];

//TESTING VARIABLE
  bool testing = false;
  bool connected = false;
  int _reconnectAttempts = 0;

  bool filterUnique = true;
  bool filterHideReady = false;
  bool priorityFilterShowReady = false;
  int bartenderCount = 1; // Number of bartenders
  int bartenderNumber = 2; // Set to bartenderCount + 1
  bool disabledTerminal = false; // Tracks if terminal is disabled
  bool barOpenStatus = true; // Track if bar is open or closed
  bool happyHour = false;
  WebSocketChannel? socket;
  bool terminalStatus = true;

  Timer? _timer;
  WebSocket? websocket;

  @override
  void initState() {
    super.initState();

 
debugPrint("Socket is ${socket == null}");
    if(socket == null) initWebsocket();

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
  
  
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }




void _updateLists() {
debugPrint("updating LIsts");
  // Sort `allOrders` by timestamp, older orders first
debugPrint("Sorting");
  allOrders.sort((a, b) => a.timestamp.compareTo(b.timestamp));
debugPrint("done sorting");

  List<CustomerOrder> claimedByBartender = [];
  List<CustomerOrder> notClaimedByBartender = [];

  // Separate orders based on whether they are claimed by the bartender
debugPrint("iterating through sorted order.");
  for (var order in allOrders) {
    if (widget.bartenderID == order.claimer && order.status != 'claimed' && order.status != 'delivered') {
      claimedByBartender.add(order);
debugPrint("iterated: claimed");
    } else if (order.status != 'claimed' && order.status != 'delivered') {
      notClaimedByBartender.add(order);
debugPrint("iterated: unclaimed");
    }
  }
debugPrint("done iterating through sortedorder");

  // Combine the lists: orders claimed by bartender first, then the rest
debugPrint("Attempting combine");
  displayList = claimedByBartender + notClaimedByBartender;
debugPrint("Done combining");


debugPrint("filtering");
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
debugPrint("Done filtring");

  // Check if terminal is disabled and no orders are claimed by the bartender
debugPrint("checking if you need to disable terminal");
  if (disabledTerminal && !allOrders.any((order) => order.claimer == widget.bartenderID)) {
    
      socket!.sink.add(
      json.encode({
        'action': 'dispose',
        'barID': widget.barID,
      }),
      );

     if (socket != null) {
        socket!.sink.close(); // Close the WebSocket connection
        socket = null; // Set the WebSocket reference to null
     }

     
      Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const BartenderIDScreen()),
      (Route<dynamic> route) => false, // Remove all previous routes
    );


  }
debugPrint("done updating lists");

if (testing) {
  // Create a list of DrinkOrder objects
  List<DrinkOrder> testDrinks = [
    DrinkOrder('drink1', 'Cocktail', "1"),
    DrinkOrder('drink2', 'Beer', "3"),
  ];

  // Create a CustomerOrder with the updated structure
  CustomerOrder testOrder = CustomerOrder(
    'bar123',                          // barId
    456,                               // userId
    29.99,                             // price
    testDrinks,                         // drinks (List<DrinkOrder>)
    'pending',                         // status
    '',                                // claimer (empty since no one has claimed the order yet)
    DateTime.now().millisecondsSinceEpoch // timestamp (current time)
  );

  allOrders.add(testOrder);
}

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


    _showAlertDialog(context, 'This station is now disabled.', 'Please complete the remaining orders to finalize the logout.');


  
    setState(() {
      terminalStatus = false;
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
  socket!.sink.add(
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
      duration: const Duration(seconds: 3),
    ),
  );
}


void _refresh() {
  allOrders.clear();
  displayList.clear();
  
  // Send a 'refresh' action to the server via WebSocket
  debugPrint("refresh sent");
  socket!.sink.add(
    jsonEncode({
      'action': 'refresh',
      'barID': widget.barID,
    }),
  );
  setState((){});
}

  void _executeFunctionForUnclaimed(CustomerOrder order) {
    // Construct the message
    final claimRequest = {
      'action': 'claim',
      'bartenderID': widget.bartenderID.toString(),
      'orderID': order.userId,
      'barID': widget.barID,
    };

    // Send the message via WebSocket
    debugPrint("claimRequest");
    socket!.sink.add(jsonEncode(claimRequest));
    debugPrint("attempting claim");
  }

void _executeFunctionForClaimed(CustomerOrder order) {
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
              ElevatedButton(
                onPressed: () {},
                onLongPress: () {
                  // Handle order cancellation here
                  debugPrint("Order canceled!");
                  socket!.sink.add(
                    json.encode({
                      'action': 'cancel',
                      'bartenderID': widget.bartenderID.toString(),
                      'orderID': order.userId,
                      'barID': widget.barID,
                    }),
                  );
                  Navigator.of(context).pop(); // Close the dialog after the action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Smaller padding
                ),
                child: const Text(
                  'Hold to cancel order',
                  style: TextStyle(fontSize: 12, color: Colors.white), // Smaller text
                ),
              ),
              const Spacer(), // Space at the top
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      debugPrint("unclaim");
                      socket!.sink.add(
                        json.encode({
                          'action': 'unclaim',
                          'bartenderID': widget.bartenderID.toString(),
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
                      'Unclaim',
                      style: TextStyle(fontSize: 20, color: Colors.white), // Larger text
                    ),
                  ),
                  const SizedBox(width: 20), // Add horizontal space between buttons
                  ElevatedButton(
                    onPressed: () {
                      debugPrint("ready");
                      socket!.sink.add(
                        json.encode({
                          'action': 'ready',
                          'bartenderID': widget.bartenderID.toString(),
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





void _executeFunctionForClaimedAndReady(CustomerOrder order) {
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
                      socket!.sink.add(
                        json.encode({
                          'action': 'cancel',
                          'bartenderID': widget.bartenderID.toString(),
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
                      socket!.sink.add(
                        json.encode({
                          'action': 'deliver',
                          'bartenderID': widget.bartenderID.toString(),
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







  void _onOrderTap(CustomerOrder order) {
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

  Color _getOrderTintColor(CustomerOrder order) {
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
  if (!connected) {
    return const Center(
      child: CircularProgressIndicator(
        color: Colors.white,
      ),
    );
  }

  return Scaffold(
    appBar: AppBar(
      title: const Center(
        child: Text('Orders'),
      ),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () {
                debugPrint("disable");
                socket!.sink.add(
                  json.encode({
                    'action': 'disable',
                    'bartenderID': widget.bartenderID.toString(),
                    'barID': widget.barID
                  }),
                );
              },
            ),
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
            _refresh();
          },
        ),
        GestureDetector(
          onLongPress: _toggleHappyHour, // Handle long press for Happy Hour
          child: Container(
            color: happyHour ? Colors.amber : Colors.grey, // Gold if happyHour is true, gray otherwise
            padding: const EdgeInsets.symmetric(horizontal: 8.0), // Add some padding around the button
            child: Center(
              child: Text(
                happyHour ? "[HOLD TO DISABLE] Happy Hour" : "[HOLD TO ENABLE] Happy Hour",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8), // Space between the Happy Hour button and the Open/Close button
        GestureDetector(
          onLongPress: _toggleBarStatus, // Handle long press for Open/Close
          child: Container(
            color: barOpenStatus ? Colors.red : Colors.green,
            child: Center(
              child: Text(
                barOpenStatus ? "[HOLD] Close Bar" : "[HOLD] Open Bar",
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
        // GestureDetector as the first child in the Stack to capture touch events first
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            // Detect a left swipe from the right edge of the screen
            if (details.primaryDelta! < -10 && details.globalPosition.dx > MediaQuery.of(context).size.width - 40) {
              _showErrorSnackbar("Showing Ready Orders");
              debugPrint("test1");
              setState(() {
                priorityFilterShowReady = true;
                _updateLists(); // Apply filters when changed
              });
            }

            // Detect a right swipe from the left edge of the screen
            if (details.primaryDelta! > 10 && details.globalPosition.dx < 40) {
              debugPrint("test2");
              _showErrorSnackbar("Showing Default");
              setState(() {
                priorityFilterShowReady = false;
                _updateLists(); // Apply filters when changed
              });
            }
          },
          child: Container(
            color: Colors.transparent, // Ensure the GestureDetector covers the entire screen area
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0), // Add horizontal padding
          child: ListView.builder(
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
                                style: const TextStyle(
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
                                style: const TextStyle(
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
                                style: const TextStyle(
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              ...order.drinks.map((drink) => Text(
                                '${drink.drinkName} x ${drink.quantity}',
                                style: const TextStyle(
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
                              )),
                              const SizedBox(height: 8),
                              Text(
                                'Status: ${order.status}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Claimed by: ${order.claimer.isEmpty ? 'N/A' : order.claimer}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Timestamp: ${DateTime.fromMillisecondsSinceEpoch(order.timestamp)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
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
    _showErrorSnackbar(error.toString());
  }
  


    void _attemptReconnect() {
    _reconnectAttempts++;
    int delay = (1 <<
        (_reconnectAttempts -
            1)); // Exponential backoff: 1, 2, 4, 8, etc. seconds
    debugPrint(
        'Scheduling reconnect attempt $_reconnectAttempts in $delay seconds.');

    Future.delayed(Duration(seconds: delay), () {
      debugPrint('Attempting to reconnect... (Attempt $_reconnectAttempts)');
      socket = null; // Ensure _channel is null before reconnecting
      initWebsocket(); // Re-attempt the connection
    });
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
debugPrint("initial connection");
       try {
      // Attempt to open a WebSocket connection
      const url = 'wss://www.barzzy.site/ws/bartenders';

      socket = WebSocketChannel.connect(Uri.parse(url));
      
      debugPrint('Connected to WebSocket at $url');

      // Send a message to initialize the bartender session
      final Map<String, dynamic> bartenderLogin = {'action': 'initialize', 'barID': widget.barID, 'bartenderID': widget.bartenderID};
      debugPrint("login");
      socket!.sink.add(jsonEncode(bartenderLogin));



socket!.stream.listen((event) {

  if (_reconnectAttempts > 0) {
              debugPrint(
                  'Connection successful. Resetting reconnect attempts.');
              _reconnectAttempts =
                  0; // Reset the reconnect attempts on successful connection
            }
  connected = true;

debugPrint('Received: $event at ${DateTime.now()}');

        // Handle the response from the server
        if (event.contains("Initialization successful")) {
          _showAlertDialog(context, "Success!", "Logged in as ${widget.bartenderID}");
          return;
          
        } else if (event.contains("Initialization failed")) {
          // Show an alert dialog if the response is unsuccessful
          _showAlertDialog(context, "Error", "Failed to initialize: $event");
            Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const BartenderIDScreen()),
            (Route<dynamic> route) => false, // Remove all previous routes
          );
          return;
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
        MaterialPageRoute(builder: (context) => const BartenderIDScreen()),
        (Route<dynamic> route) => false, // Remove all previous routes
      );
        if (socket != null) {
        socket!.sink.close(); // Close the WebSocket connection
        socket = null; // Set the WebSocket reference to null
  }

      break;

    case 'barId':
    final Map<String, dynamic> ordersJson = response;

    final incomingOrder = CustomerOrder.fromJson(ordersJson);

      // Check if the order exists in allOrders
      int index = allOrders.indexWhere((order) => order.userId == incomingOrder.userId);
      if (index != -1) {
        // If it exists, replace the old order
        allOrders[index] = incomingOrder;
        if( allOrders[index].status == 'delivered' || allOrders[index].status == 'canceled') allOrders.remove(allOrders[index]);
      } else  {
        // If it doesn't exist, add the new order to allOrders
        if( incomingOrder.status != 'delivered' && incomingOrder.status != 'canceled') allOrders.add(incomingOrder);
                  
      }
    
      setState(() {
        // Update the displayList based on the new allOrders
        _updateLists();
      });
      break;



    case 'orders':
      final List<dynamic> ordersJson = response['orders'];



      // Convert JSON to Order objects and update allOrders
      final incomingOrders = ordersJson.map((json) => CustomerOrder.fromJson(json)).toList();
      for (CustomerOrder incomingOrder in incomingOrders) {
        // Check if the order exists in allOrders
        int index = allOrders.indexWhere((order) => order.userId == incomingOrder.userId);
        if (index != -1) {
          // If it exists, replace the old order
          allOrders[index] = incomingOrder;
          if( allOrders[index].status == 'delivered' || allOrders[index].status == 'canceled') allOrders.remove(allOrders[index]);
        } else  {
          // If it doesn't exist, add the new order to allOrders
          if( incomingOrder.status != 'delivered' && incomingOrder.status != 'canceled') allOrders.add(incomingOrder);
                    
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
                    debugPrint("BarState set to $barOpenStatus" );
        });
        break;

    case 'happyHour':
       // Update barOpenStatus and refresh UI
        setState(() {
          happyHour = response['happyHour'];
          debugPrint("Happy hour set to $happyHour" );
        });
        break;

    case 'disable':
        _disableTerminal();
        break;

    case 'updateTerminal':
        // Update local values and refresh UI
        setState(() {
          bartenderCount = int.parse(response['bartenderCount']);
          bartenderNumber = int.parse(response['bartenderNumber']);
        });
        break;

    default:
      debugPrint("Unknown key received in WebSocket message: ${response.keys.first}");
  }
},
    onError: (error) {
      if(!disabledTerminal) _handleWebSocketError(error);
    },
    onDone: () {

debugPrint('WebSocket connection closed');
      connected = false;
      if(!disabledTerminal) _attemptReconnect(); 

      
    },
    cancelOnError: false, // Optionally, cancel the listener on error
  );

    } catch (e) {
      // Handle the error
      connected = false;
      _attemptReconnect();
debugPrint('Failed to connect to WebSocket: $e');
    }
  }


  void _toggleHappyHour() {


debugPrint('Happy Hour Toggled');
  socket!.sink.add(
  json.encode({
    'action': happyHour ? 'sadHour' : 'happyHour',
    'barID': widget.barID,
  }),
  );


  }
}

