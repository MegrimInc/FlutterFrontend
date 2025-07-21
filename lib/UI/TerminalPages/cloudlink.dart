// ignore_for_file: use_build_context_synchronously

import 'dart:async'; // Import the async package for Timer
import 'dart:convert';
import 'dart:io';
import 'package:megrim/config.dart';
import 'package:http/http.dart' as http;
import 'package:megrim/DTO/terminalorder.dart';
import 'package:megrim/UI/TerminalPages/select.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class CloudLinkPage extends StatefulWidget {
  final int employeeId; // Terminal Id parameter
  final int merchantId;
  final PageController pageController;

  const CloudLinkPage(
      {super.key,
      required this.employeeId,
      required this.merchantId,
      required this.pageController});

  @override
  State<CloudLinkPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<CloudLinkPage>
    with WidgetsBindingObserver {
  List<TerminalOrder> allOrders = [];
  List<TerminalOrder> sortedOrders = [];
  bool connected = false;
  int _reconnectAttempts = 0;
  WebSocketChannel? socket;
  Timer? _timer;
  Timer? _heartbeatTimer;
  WebSocket? websocket;

  @override
  void initState() {
    super.initState();

    debugPrint("Socket is ${socket == null}");
    if (socket == null) initWebsocket();

    // Start a timer to update the list and send heartbeat every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateLists();
    });
  }

  Future<double> fetchTipAmount() async {
    String url =
        "${AppConfig.postgresHttpBaseUrl}/order/getTotalGratuity?terminal=${widget.employeeId}&merchantId=${widget.merchantId}";
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        //body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        // Decode the JSON object from the backend
        final Map<String, dynamic> data = jsonDecode(response.body);
        // Extract the tipTotal field and convert it to double if necessary
        return (data['tipTotal'] as num).toDouble();
      } else {
        debugPrint(
            "Error fetching tip amount. Status code: ${response.statusCode}");
        return 0.0;
      }
    } catch (error) {
      debugPrint("Error fetching tip amount: $error");
      return 0.0;
    }
  }

  void _updateLists() {
    debugPrint("Starting _updateLists...");

    setState(() {
      // Separate "arrived" orders
      List<TerminalOrder> arrivedOrders =
          allOrders.where((order) => order.status == 'arrived').toList();

      // Separate claimed and unclaimed orders, excluding "arrived" orders
      List<TerminalOrder> claimedOrders = allOrders
          .where((order) =>
              order.employeeId == widget.employeeId &&
              order.status != 'arrived') //&& order.status != 'ready')
          .toList();

      List<TerminalOrder> unclaimedOrders = allOrders
          .where((order) =>
              order.employeeId != widget.employeeId &&
              order.status != 'arrived') //&& order.status != 'ready')
          .toList();

      // Sort each category by timestamp (older first)
      arrivedOrders.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      claimedOrders.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      unclaimedOrders.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Combine sorted lists
      sortedOrders = [
        ...arrivedOrders,
        ...claimedOrders,
        ...unclaimedOrders,
      ];
    });

    _heartbeat();

    debugPrint("Finished _updateLists.");
  }

  void _heartbeat() {
    debugPrint('Heartbeat ping sent at ${DateTime.now()}');
    socket?.sink.add(jsonEncode({
      'action': 'ping',
    }));
  }

  void _refresh() {
    debugPrint("Manual refresh triggered");

    allOrders.clear();
    sortedOrders.clear();

    try {
      socket!.sink.close(); // Gracefully close old connection
      debugPrint("Closed existing socket.");
    } catch (e) {
      debugPrint("Error closing socket: $e");
    }
  }

  void _onOrderTap(TerminalOrder order) {
    if (order.employeeId == widget.employeeId) {
      if (order.status == 'ready' || order.status == 'arrived') {
        _executeFunctionForDeliverOrCancel(order);
      } else {
        _executeFunctionForReady(order);
      }
    }
  }

  void _executeFunctionForReady(TerminalOrder order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(135, 36, 36, 36),
          title: Center(
            child: Text(
              order.name,
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
                            'employeeId': widget.employeeId,
                            'customerId': order.customerId,
                            'merchantId': widget.merchantId,
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
                        width: 20), // Add horizontal space between buttons
                    ElevatedButton(
                      onPressed: () {
                        debugPrint("ready");
                        socket!.sink.add(
                          json.encode({
                            'action': 'ready',
                            'employeeId': widget.employeeId,
                            'customerId': order.customerId,
                            'merchantId': widget.merchantId,
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

  void _executeFunctionForDeliverOrCancel(TerminalOrder order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(135, 36, 36, 36),
          title: Center(
            child: Text(
              order.name,
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
                            'employeeId': widget.employeeId,
                            'customerId': order.customerId,
                            'merchantId': widget.merchantId,
                          }),
                        );
                        Navigator.of(context).pop();
                        if (order.status == "arrived" &&
                            order.pointOfSale == "cloudcast") {
                          // Navigate to page 0 if conditions are met
                          widget.pageController.animateToPage(
                            1,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
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
                            'employeeId': widget.employeeId,
                            'customerId': order.customerId,
                            'merchantId': widget.merchantId,
                          }),
                        );

                        Navigator.of(context).pop();

                        if (order.status == "arrived" &&
                            order.pointOfSale == "cloudcast") {
                          // Navigate to page 0 if conditions are met
                          widget.pageController.animateToPage(
                            1,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
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

  Color? _getOrderTintColor(TerminalOrder order) {
    if (order.status == 'ready') return Colors.green;
    if (order.status == 'unready') return Colors.orange[200]; // Over 10 minutes old
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: connected
          ? _buildOrderList(sortedOrders)
          : const Center(
              child: SizedBox(
                  width: 60, // set width
                  height: 60, // set height
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  )),
            ),
    );
  }

  Widget _buildOrderList(List<TerminalOrder> displayList) {
    return RefreshIndicator(
      onRefresh: () async {
        _refresh();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ListView.builder(
          itemCount: displayList.length,
          itemBuilder: (context, index) {
            final order = displayList[index];
            final tintColor = _getOrderTintColor(order);
            final paidItems = order.items;

            return GestureDetector(
              onTap: () => _onOrderTap(order),
              child: Card(
                margin: const EdgeInsets.all(8.0),
                color: tintColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(children: [
                        Text(
                          order.name,
                          style: const TextStyle(
                            fontSize: 21,
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
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Text(
                          'Tip: \$${order.totalGratuity}',
                          style: const TextStyle(
                            fontSize: 21,
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
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]),
                    ),
                    IntrinsicHeight(
                      child: Center(
                        child: Column(
                          children: [
                            ..._aggregateItems(paidItems).map((itemData) =>
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 5.0),
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${itemData['itemName']} x ',
                                          style: const TextStyle(
                                            fontSize: 22,
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
                                        TextSpan(
                                          text: '${itemData['quantity']}',
                                          style: const TextStyle(
                                            fontSize:
                                                26, // 🔥 Bigger font for quantity
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
                                )),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order.pointOfSale == 'cloudlink'
                                ? '*CL'
                                : (order.pointOfSale == 'cloudcats'
                                    ? '*CC'
                                    : order.pointOfSale),
                            style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    offset: Offset(1.0, 1.0),
                                    blurRadius: 1.0,
                                  ),
                                ]),
                          ),
                          Text(
                            formatElapsedTime(order.getAge()),
                            style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    offset: Offset(1.0, 1.0),
                                    blurRadius: 1.0,
                                  ),
                                ]),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // 🧮 Helper function to aggregate item quantities by itemId
  List<Map<String, dynamic>> _aggregateItems(List<dynamic> items) {
    final Map<int, Map<String, dynamic>> aggregated = {};

    for (var item in items) {
      if (aggregated.containsKey(item.itemId)) {
        aggregated[item.itemId]!['quantity'] +=
            item.quantity; // 🔁 Sum quantity
      } else {
        aggregated[item.itemId] = {
          'itemName': item.itemName,
          'quantity': item.quantity,
        };
      }
    }

    return aggregated.values.toList(); // 🔁 Return combined list
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
          ),
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating, // Optional: lifts the snackbar
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
      final url = '${AppConfig.redisWsBaseUrl}/terminals';

      socket = WebSocketChannel.connect(Uri.parse(url));

      debugPrint('Connected to WebSocket at $url');

      // Send a message to initialize the terminal session
      final Map<String, dynamic> terminalLogin = {
        'action': 'initialize',
        'merchantId': widget.merchantId,
        'employeeId': widget.employeeId
      };
      debugPrint("terminal id login");

      socket!.sink.add(jsonEncode(terminalLogin));

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

          //debugPrint('Received: $event at ${DateTime.now()}');

          // Handle the response from the server
          if (event.contains("Initialization successful")) {
            return;
          } else if (event.contains("Initialization failed")) {
            // Show an alert dialog if the response is unsuccessful
            _showAlertDialog(context, "Error", "Failed to initialize: $event");
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const SelectPage()),
              (Route<dynamic> route) => false, // Remove all previous routes
            );
            return;
          }

          // Parse the JSON response from the server
          final Map<String, dynamic> response = jsonDecode(event);

          // Check which key is present in the response and handle accordingly
          switch (response.keys.first) {
            case 'error':
              // Use _showErrorSnackmerchant to display the error message
              _showErrorSnackbar(response['error']);
              break;

            case 'terminate':
              _showErrorSnackbar(
                  "Connection terminated by the server: new connection inbound");
              if (socket != null) {
                socket!.sink.close(); // Close the WebSocket connection
                socket = null; // Set the WebSocket reference to null
              }
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const SelectPage()),
                (Route<dynamic> route) => false, // Remove all previous routes
              );
              break;

            case 'orders':
              final List<dynamic> ordersJson = response['orders'];

              // Convert JSON to Order objects and update allOrders
              final incomingOrders = ordersJson
                  .map((json) => TerminalOrder.fromJson(json))
                  .toList();
              for (TerminalOrder incomingOrder in incomingOrders) {
                // Check if the order exists in allOrders
                int index = allOrders.indexWhere(
                    (order) => order.customerId == incomingOrder.customerId);
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
              _updateLists();
              break;

            case 'update':
              final List<dynamic> ordersJson = response['update'];

              // Convert JSON to Order objects and update allOrders
              final incomingOrders = ordersJson
                  .map((json) => TerminalOrder.fromJson(json))
                  .toList();
              for (TerminalOrder incomingOrder in incomingOrders) {
                // Check if the order exists in allOrders
                int index = allOrders.indexWhere(
                    (order) => order.customerId == incomingOrder.customerId);
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
              _updateLists();
              break;

            case 'heartbeat':
              debugPrint('Still Alive');
              break;

            default:
              debugPrint(
                  "Unknown key received in WebSocket message: ${response.keys.first}");
          }
        },
        onError: (error) {
          _handleWebSocketError(error);
        },
        onDone: () {
          debugPrint('WebSocket connection closed');

          setState(() {
            connected = false;
          });

          _attemptReconnect();
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

  String formatElapsedTime(int seconds) {
    if (seconds < 0) {
      return "0m"; // Prevent negative minutes
    }

    int minutes = (seconds / 60).floor();
    return "$minutes m";
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    socket?.sink.close();
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}
