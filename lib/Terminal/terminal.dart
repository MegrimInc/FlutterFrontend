// ignore_for_file: use_build_context_synchronously

import 'dart:async'; // Import the async package for Timer
import 'dart:convert'; //TODO check bar is active
import 'dart:io';


import 'package:barzzy/Backend/activeorder.dart';
import 'package:barzzy/Terminal/stationid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class OrdersPage extends StatefulWidget {
  final String bartenderID; // Bartender ID parameter
  final int barID;

  const OrdersPage({
    super.key,
    required this.bartenderID,
    required this.barID,
  });

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
  bool filterReady = false;
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
    if (socket == null) initWebsocket();

    // Initialize filters and bartender number
    filterUnique = true;
    bartenderNumber = 0;
    bartenderCount = 1;

    // Start a timer to update the list every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateLists();
    });

    // Listen for the response from the server

    _updateLists();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  void _updateLists() {
    setState(() {
      // Sort `allOrders` by timestamp, older orders first
      allOrders.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      List<CustomerOrder> filteredOrders = allOrders;

      // Filter based on `filterReady`
      if (filterReady) {
        // Show only ready orders
        filteredOrders =
            filteredOrders.where((order) => order.status == 'ready').toList();
      } else {
        // Show only unready orders
        filteredOrders =
            filteredOrders.where((order) => order.status != 'ready').toList();
      }

      // Apply the "Your Orders Only" filter if `filterUnique` is true
      if (filterUnique) {
        filteredOrders = filteredOrders
            .where((order) =>
                order.claimer == widget.bartenderID ||
                (order.claimer.isEmpty &&
                    (order.userId % bartenderCount) == bartenderNumber))
            .toList();
      }

      // Update the display list with the filtered orders
      displayList = filteredOrders;

      // Check if terminal is disabled and no orders are claimed by the bartender
      if (disabledTerminal &&
          !allOrders.any((order) => order.claimer == widget.bartenderID)) {
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

      if (testing) {
        // Create a list of DrinkOrder objects
        List<DrinkOrder> testDrinks = [
          DrinkOrder('drink1', 'Cocktail', "1"),
          DrinkOrder('drink2', 'Beer', "3"),
        ];

        // Create a CustomerOrder with the updated structure
        CustomerOrder testOrder = CustomerOrder(
            'bar123', // barId
            456, // userId
            29.99, // price
            testDrinks, // drinks (List<DrinkOrder>)
            'pending', // status
            '', // claimer (empty since no one has claimed the order yet)
            DateTime.now().millisecondsSinceEpoch // timestamp (current time)
            );

        allOrders.add(testOrder);
      }
    });
  }

  void _disableTerminal() {
    // Check if there are any orders that are not marked as delivered or canceled
    bool hasPendingOrders = allOrders.any(
        (order) => order.status != 'delivered' && order.status != 'canceled');

    // Only show alert dialog if there are pending orders
    if (hasPendingOrders) {
      _showAlertDialog(context, 'This station is now disabled.',
          'Please complete the remaining orders to finalize the logout.');
    }

    setState(() {
      terminalStatus = false;
      bartenderNumber = bartenderCount;
      filterUnique = true;
      filterReady = false;
      disabledTerminal = true;
    });

    // Refresh the list after disabling the terminal
    _updateLists();
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Your Orders Only'),
                  Switch(
                    value: filterUnique,
                    onChanged: (bool value) {
                      setState(() {
                        filterUnique = value;
                      });
                      this.setState(() {
                        _updateLists(); // Apply filters when changed
                      });
                    },
                    activeColor: Colors.black,
                  ),
                ],
              );
            },
          ),
        ),
        PopupMenuItem(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('            Open'),
                  Switch(
                    value: barOpenStatus,
                    onChanged: (bool value) {
                      setState(() {
                        barOpenStatus = value;
                      });
                      this.setState(() {
                        _toggleBarStatus(); // Trigger Bar status toggle
                      });
                    },
                    activeColor: Colors.black,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
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
    setState(() {});
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
          backgroundColor: const Color.fromARGB(135, 36, 36, 36),
          title: Center(
            child: Text(
              'Order #${order.userId}',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white), // Larger title
            ),
          ),
          content: SizedBox(
            height: 125, // Increase the height of the dialog
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // ElevatedButton(
                //   onPressed: () {},
                //   onLongPress: () {
                //     // Handle order cancellation here
                //     debugPrint("Order canceled!");
                //     socket!.sink.add(
                //       json.encode({
                //         'action': 'cancel',
                //         'bartenderID': widget.bartenderID.toString(),
                //         'orderID': order.userId,
                //         'barID': widget.barID,
                //       }),
                //     );
                //     Navigator.of(context)
                //         .pop(); // Close the dialog after the action
                //   },
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.grey,
                //     padding: const EdgeInsets.symmetric(
                //         horizontal: 16, vertical: 8), // Smaller padding
                //   ),
                //   child: const Text(
                //     'Hold to cancel order',
                //     style: TextStyle(
                //         fontSize: 12, color: Colors.white), // Smaller text
                //   ),
                // ),
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
                            horizontal: 32,
                            vertical: 32), // Double the vertical padding
                      ),
                      child: const Text(
                        'Unclaim',
                        style: TextStyle(
                            fontSize: 20, color: Colors.white), // Larger text
                      ),
                    ),
                    const SizedBox(
                        width: 20), // Add horizontal space between buttons
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
                            horizontal: 32,
                            vertical: 32), // Double the vertical padding
                      ),
                      child: const Text(
                        'Ready',
                        style: TextStyle(
                            fontSize: 20, color: Colors.white), // Larger text
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
          backgroundColor: const Color.fromARGB(135, 36, 36, 36),
          title: Center(
            child: Text(
              'Order #${order.userId}',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white), // Larger title
            ),
          ),
          content: SizedBox(
            height: 125, // Increase the height of the dialog
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
                            horizontal: 32,
                            vertical: 32), // Double the vertical padding
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                            fontSize: 20, color: Colors.white), // Larger text
                      ),
                    ),
                    const SizedBox(
                        width:
                            30), // Increased horizontal space between buttons
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
                            horizontal: 32,
                            vertical: 32), // Double the vertical padding
                      ),
                      child: const Text(
                        'Deliver',
                        style: TextStyle(
                            fontSize: 20, color: Colors.white), // Larger text
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
    if (order.claimer != '' && order.claimer != widget.bartenderID) {
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
    debugPrint("Rebuilding OrdersPage with ${displayList.length} items");
    if (!connected) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // Distribute items evenly
          children: [
            // Leading icon (Power Off)
            IconButton(
              icon: Icon(disabledTerminal ? Icons.power_off : Icons.power),
              color: Colors.white,
              onPressed: () {
                if (!disabledTerminal) {
                  debugPrint("disable");
                  socket!.sink.add(
                    json.encode({
                      'action': 'disable',
                      'bartenderID': widget.bartenderID.toString(),
                      'barID': widget.barID,
                    }),
                  );
                }
              },
            ),

            // Filter status icons (Non-ready and Ready)
            Row(
              children: [
                Icon(
                  filterReady ? Icons.circle_outlined : Icons.circle,
                  color: Colors.white,
                  size: 12.0, // Adjust the size as needed
                ),
                const SizedBox(width: 8),
                Icon(
                  filterReady ? Icons.circle : Icons.circle_outlined,
                  color: Colors.white,
                  size: 12.0, // Adjust the size as needed
                ),
              ],
            ),

            // Filter menu icon
            IconButton(
              icon: const Icon(Icons.filter_list),
              color: Colors.white,
              iconSize: 28,
              onPressed: _showFilterMenu, // Open the popup menu with toggles
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              _refresh(); // Call your existing refresh method
            },
            child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8.0), // Add horizontal padding
                child: ListView.builder(
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final order = displayList[index];
                    final tintColor = _getOrderTintColor(order);

                    return GestureDetector(
                      onTap: () => {
                        _onOrderTap(order),
                      },
                      child: Card(
                        margin: const EdgeInsets.all(8.0),
                        color: tintColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .spaceBetween, // Distribute items evenly
                              crossAxisAlignment: CrossAxisAlignment
                                  .center, // Center items vertically
                              children: <Widget>[
                                // Claimer or SpinKit
                                order.claimer.isEmpty
                                    ? const SpinKitThreeBounce(
                                        color: Colors.white,
                                        size: 30.0,
                                      )
                                    : Text(
                                        '@${order.claimer}', // Add @ symbol
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

                                // Drinks list centered
                                Column(
                                  mainAxisAlignment: MainAxisAlignment
                                      .center, // Center items vertically
                                  crossAxisAlignment: CrossAxisAlignment
                                      .center, // Center items horizontally
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
                                  ],
                                ),

                                // Order ID on the right
                                Text(
                                  '#${order.userId}',
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
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )),
          ),

          // Positioned widget on the right side for swipe detection
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 125, // Adjust this width as needed
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.velocity.pixelsPerSecond.dx < 0) {
                  setState(() {
                    filterReady = true;
                    _updateLists(); // Apply filters when changed
                  });
                }
              },
              child: Container(
                color: Colors
                    .transparent, // Optional: change to transparent in production
              ),
            ),
          ),

// Positioned widget on the left side for swipe detection
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 125, // Adjust this width as needed
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.velocity.pixelsPerSecond.dx > 0) {
                  setState(() {
                    filterReady = false;
                    _updateLists(); // Apply filters when changed
                  });
                }
              },
              child: Container(
                color: Colors
                    .transparent, // Optional: change to transparent in production
              ),
            ),
          ),
        ],
      ),
    );
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.black87, // Dark background color
          title: Center(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white, // White title text
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          content: Text(
            content,
            style: const TextStyle(
              color: Colors.white70, // Slightly dimmed white for content
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            Center(
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey, // Blue button background
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white, // White button text
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss the dialog
                },
              ),
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
      final Map<String, dynamic> bartenderLogin = {
        'action': 'initialize',
        'barID': widget.barID,
        'bartenderID': widget.bartenderID
      };
      debugPrint("login");
      socket!.sink.add(jsonEncode(bartenderLogin));

      socket!.stream.listen(
        (event) {
          if (_reconnectAttempts > 0) {
            debugPrint('Connection successful. Resetting reconnect attempts.');
            _reconnectAttempts =
                0; // Reset the reconnect attempts on successful connection
          }
          setState(() {
            connected = true;
          });

          debugPrint('Received: $event at ${DateTime.now()}');

          // Handle the response from the server
          if (event.contains("Initialization successful")) {
            return;
          } else if (event.contains("Initialization failed")) {
            // Show an alert dialog if the response is unsuccessful
            _showAlertDialog(context, "Error", "Failed to initialize: $event");
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => const BartenderIDScreen()),
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
              _showErrorSnackbar(
                  "Connection terminated by the server: new connection inbound");
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => const BartenderIDScreen()),
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
              int index = allOrders
                  .indexWhere((order) => order.userId == incomingOrder.userId);
              if (index != -1) {
                // If it exists, replace the old order
                allOrders[index] = incomingOrder;
                if (allOrders[index].status == 'delivered' ||
                    allOrders[index].status == 'canceled') {
                  allOrders.remove(allOrders[index]);
                }
              } else {
                // If it doesn't exist, add the new order to allOrders
                if (incomingOrder.status != 'delivered' &&
                    incomingOrder.status != 'canceled') {
                  allOrders.add(incomingOrder);
                }
              }

              setState(() {
                // Update the displayList based on the new allOrders
                _updateLists();
              });
              break;

            case 'orders':
              final List<dynamic> ordersJson = response['orders'];

              // Convert JSON to Order objects and update allOrders
              final incomingOrders = ordersJson
                  .map((json) => CustomerOrder.fromJson(json))
                  .toList();
              for (CustomerOrder incomingOrder in incomingOrders) {
                // Check if the order exists in allOrders
                int index = allOrders.indexWhere(
                    (order) => order.userId == incomingOrder.userId);
                if (index != -1) {
                  // If it exists, replace the old order
                  allOrders[index] = incomingOrder;
                  if (allOrders[index].status == 'delivered' ||
                      allOrders[index].status == 'canceled') {
                    allOrders.remove(allOrders[index]);
                  }
                } else {
                  // If it doesn't exist, add the new order to allOrders
                  if (incomingOrder.status != 'delivered' &&
                      incomingOrder.status != 'canceled') {
                    allOrders.add(incomingOrder);
                  }
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
                debugPrint("BarState set to $barOpenStatus");
              });
              break;

            case 'disable':
              _disableTerminal();
              break;

            case 'updateTerminal':
              debugPrint(
                  'updateTerminal received: ${response['bartenderCount']}, ${response['bartenderNumber']}');
              bartenderCount = int.parse(response['bartenderCount']);
              bartenderNumber = int.parse(response['bartenderNumber']);
              _updateLists();
              debugPrint('Set state triggered for updateTerminal');
              break;

            default:
              debugPrint(
                  "Unknown key received in WebSocket message: ${response.keys.first}");
          }
        },
        onError: (error) {
          if (!disabledTerminal) _handleWebSocketError(error);
        },
        onDone: () {
          debugPrint('WebSocket connection closed');

          setState(() {
            connected = false;
          });

          if (!disabledTerminal) _attemptReconnect();
        },
        cancelOnError: false, // Optionally, cancel the listener on error
      );
    } catch (e) {
      // Handle the error
      setState(() {
        connected = false;
      });
      _attemptReconnect();
      debugPrint('Failed to connect to WebSocket: $e');
    }
  }

  void _toggleBarStatus() {
    // Log the action
    debugPrint(barOpenStatus ? 'open' : 'close' ' sent');

    // Send the open/close action to the server
    socket!.sink.add(
      json.encode({
        'action': barOpenStatus ? 'open' : 'close',
        'barID': widget.barID,
      }),
    );

    // Log the new bar status
    debugPrint(
        'Bar status toggled. New status: ${barOpenStatus ? "Open" : "Closed"}');
  }
}
