// ignore_for_file: use_build_context_synchronously

import 'dart:async'; // Import the async package for Timer
import 'dart:convert';
import 'dart:io';
import 'package:barzzy/Terminal/inventory.dart';
import 'package:barzzy/Terminal/pos.dart';
import 'package:barzzy/config.dart';
import 'package:http/http.dart' as http;
import 'package:barzzy/Backend/bartender_order.dart';
import 'package:barzzy/Terminal/select.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Terminal extends StatefulWidget {
  final String bartenderID; // Bartender ID parameter
  final int barID;

  const Terminal({super.key, required this.bartenderID, required this.barID});

  @override
  State<Terminal> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<Terminal> {
  List<BartenderOrder> allOrders = [];
  List<BartenderOrder> sortedOrders = [];
  final PageController _pageController = PageController(initialPage: 1);
  int index = 1;
  bool testing = false;
  bool connected = false;
  int _reconnectAttempts = 0;
  bool filterUnique = true;
  int bartenderCount = 1; // Number of bartenders
  int bartenderNumber = 2; // Set to bartenderCount + 1
  bool disabledTerminal = false; // Tracks if terminal is disabled
  bool barOpenStatus = true; // Track if bar is open or closed
  bool happyHour = false;
  WebSocketChannel? socket;
  bool terminalStatus = true;
  Timer? _timer;
  Timer? _heartbeatTimer;
  WebSocket? websocket;

  @override
  void initState() {
    super.initState();

    debugPrint("Socket is ${socket == null}");
    if (socket == null) initWebsocket();

    _setUpInventory();

    // Initialize filters and bartender number
    filterUnique = true;
    bartenderNumber = 0;
    bartenderCount = 1;

    // Start a timer to update the list and send heartbeat every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateLists();
    });
  }

  Future<void> _setUpInventory() async {
    try {
      debugPrint("Setting up inventory...");
      final inv = Provider.of<Inventory>(context, listen: false);
      await inv
          .fetchBarDetails(widget.barID); // Call fetchBarDetails with the barID
      debugPrint("Inventory setup completed successfully.");
    } catch (e) {
      debugPrint("Error setting up inventory: $e");
    }
  }

  Future<double> fetchTipAmount() async {
    String url =
        "${AppConfig.postgresApiBaseUrl}/orders/gettips?terminalId=${widget.bartenderID}&merchantId=${widget.barID}";
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
      List<BartenderOrder> arrivedOrders =
          allOrders.where((order) => order.status == 'arrived').toList();

      // Separate claimed and unclaimed orders, excluding "arrived" orders
      List<BartenderOrder> claimedOrders = allOrders
          .where((order) =>
              order.claimer == widget.bartenderID &&
              order.status != 'arrived') //&& order.status != 'ready')
          .toList();

      List<BartenderOrder> unclaimedOrders = allOrders
          .where((order) =>
              order.claimer != widget.bartenderID &&
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

      if (filterUnique) {
        sortedOrders = sortedOrders
            .where((order) =>
                order.claimer == widget.bartenderID ||
                (order.claimer.isEmpty &&
                    (order.userId % bartenderCount) == bartenderNumber))
            .toList();
      }

      // Handle terminal disablement logic
      if (disabledTerminal &&
          !allOrders.any((order) => order.claimer == widget.bartenderID)) {
        socket!.sink.add(
          json.encode({
            'action': 'disable',
            'barID': widget.barID,
          }),
        );

        if (socket != null) {
          socket!.sink.close();
          socket = null;
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const BartenderIDScreen()),
          (Route<dynamic> route) => false,
        );
      }
    });

    _heartbeat();

    debugPrint("Finished _updateLists.");
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
        kToolbarHeight + 21,
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

  void _executeFunctionForUnclaimed(BartenderOrder order) {
    // Construct the message
    final claimRequest = {
      'action': 'claim',
      'bartenderID': widget.bartenderID.toString(),
      'userID': order.userId,
      'barID': widget.barID,
    };

    // Send the message via WebSocket
    debugPrint("claimRequest");
    socket!.sink.add(jsonEncode(claimRequest));
    debugPrint("attempting claim");
  }

  void _executeFunctionForClaimed(BartenderOrder order) {
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
                        debugPrint("unclaim");
                        socket!.sink.add(
                          json.encode({
                            'action': 'unclaim',
                            'bartenderID': widget.bartenderID.toString(),
                            'userID': order.userId,
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
                            'userID': order.userId,
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

  void _executeFunctionForClaimedAndReady(BartenderOrder order) {
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
                            'bartenderID': widget.bartenderID.toString(),
                            'userID': order.userId,
                            'barID': widget.barID,
                          }),
                        );
                        Navigator.of(context).pop();
                        if (order.status == "arrived" && order.pointOfSale) {
                          // Navigate to page 0 if conditions are met
                          _pageController.animateToPage(
                            0,
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
                            'bartenderID': widget.bartenderID.toString(),
                            'userID': order.userId,
                            'barID': widget.barID,
                          }),
                        );

                        Navigator.of(context).pop();

                        if (order.status == "arrived" && order.pointOfSale) {
                          // Navigate to page 0 if conditions are met
                          _pageController.animateToPage(
                            0,
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

  void _onOrderTap(BartenderOrder order) {
    if (order.claimer.isEmpty) {
      _executeFunctionForUnclaimed(order);
    } else if (order.claimer == widget.bartenderID) {
      if (order.status == 'ready' || order.status == 'arrived') {
        _executeFunctionForClaimedAndReady(order);
      } else {
        _executeFunctionForClaimed(order);
      }
    }
  }

  Color _getOrderTintColor(BartenderOrder order) {
    final ageInSeconds = order.getAge();

    // Debug print to show age and userID
    if (order.claimer != '' && order.claimer != widget.bartenderID) {
      return Colors.grey[700]!;
    }

    if (order.status == 'ready') return Colors.green;
    if (order.status == 'arrived') {
      return order.pointOfSale ? Colors.purple : Colors.blueAccent;
    }
    if (ageInSeconds <= 180) return Colors.orange[200]!; // 0-3 minutes old
    if (ageInSeconds <= 300) return Colors.orange[200]!; // 3-5 minutes old
    if (ageInSeconds <= 600) return Colors.orange[200]!; // 5-10 minutes old
    return Colors.orange[200]!; // Over 10 minutes old
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon:
                        Icon(disabledTerminal ? Icons.power_off : Icons.power),
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
                  const SizedBox(width: 5),
                  const Icon(Icons.person, color: Colors.grey),
                  const SizedBox(width: 2.5),
                  Text(
                    '$bartenderCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ), // Small spacing between icon and count
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(2, (pageIndex) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Icon(
                          Icons.circle,
                          color:
                              index == pageIndex ? Colors.white : Colors.grey,
                          size: 12.0,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      claimTips();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text(
                      "Claim Tips",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    color: Colors.white,
                    iconSize: 28,
                    onPressed: _showFilterMenu,
                  ),
                ],
              ),
            ],
          ),
        ),
        body: connected
            ? PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.horizontal,
                itemCount: 2,
                onPageChanged: (pageIndex) {
                  setState(() {
                    index = pageIndex;
                    debugPrint("Page changed to: $index");
                  });
                },
                itemBuilder: (context, pageIndex) {
                  if (pageIndex == 0) {
                    return POSPage(
                      bartenderId: widget.bartenderID,
                      pageController: _pageController,
                    );
                  } else if (pageIndex == 1) {
                    return _buildOrderList(sortedOrders);
                  }
                  return null;
                },
              )
            : const Center(
                child: SizedBox(
                    width: 60, // set width
                    height: 60, // set height
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    )),
              ),
      ),
    );
  }

  Widget _buildOrderList(List<BartenderOrder> displayList) {
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
            final paidDrinks = order.drinks;

            String formatDrink(DrinkOrder drink) {
              return drink.sizeType.isNotEmpty
                  ? '${drink.drinkName} (${drink.sizeType}) x ${drink.quantity}'
                  : '${drink.drinkName} x ${drink.quantity}';
            }

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
                          '*${order.name}',
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
                          'Tip: \$${order.tip}',
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
                            ...paidDrinks.map((drink) => Text(
                                  formatDrink(drink),
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
                                  textAlign: TextAlign.center,
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
                          order.claimer.isEmpty
                              ? const SpinKitThreeBounce(
                                  color: Colors.white,
                                  size: 25.0,
                                )
                              : Text(
                                  '@${order.claimer}',
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

  void claimTips() async {
    bool isSubmitting = false; // Track button status within the dialog

    double tipAmount = await fetchTipAmount();

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (BuildContext context) {
        final TextEditingController nameController = TextEditingController();
        final TextEditingController emailController = TextEditingController();

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(
                'Claim tips for ${widget.bartenderID} (\$${tipAmount.toStringAsFixed(2)})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController, // Assign the controller
                    cursorColor: Colors.black, // Set the cursor color to black
                    decoration: const InputDecoration(
                      labelText: "Your Name",
                      labelStyle: TextStyle(color: Colors.black),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color:
                                Colors.black), // Set underline color to black
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        // Enable Submit if name field is not empty
                        isSubmitting = value.isEmpty;
                      });
                    },
                  ),
                  TextField(
                    controller: emailController, // Assign the controller
                    cursorColor: Colors.black, // Set the cursor color to black
                    decoration: const InputDecoration(
                      labelText: "Your Email (optional)",
                      labelStyle: TextStyle(color: Colors.black),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color:
                                Colors.black), // Set underline color to black
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Cancel button
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text("Cancel",
                            style: TextStyle(color: Colors.white)),
                      ),

                      const SizedBox(width: 100),
                      TextButton(
                        onPressed: isSubmitting
                            ? null // Disable if currently submitting
                            : () async {
                                if (nameController.text.isNotEmpty) {
                                  debugPrint(
                                      "Attempting to submit request for claimTips");

                                  final Map<String, dynamic> request = {
                                    'bartenderName': nameController.text,
                                    'bartenderEmail': emailController.text,
                                    'station': widget.bartenderID,
                                    'barId': widget.barID,
                                  };

                                  setState(() {
                                    isSubmitting =
                                        true; // Temporarily disable button
                                  });

                                   String url =
                                      "${AppConfig.postgresApiBaseUrl}/orders/claim";

                                  try {
                                    final response = await http.post(
                                      Uri.parse(url),
                                      headers: {
                                        'Content-Type': 'application/json'
                                      },
                                      body: jsonEncode(request),
                                    );

                                    if (response.statusCode == 200) {
                                      debugPrint(
                                          "Successfully submitted request for claimTips");
                                      final responseData =
                                          jsonDecode(response.body);

                                      final double claimedTips = double.parse(
                                          responseData
                                              .toString()); // Assuming the key is 'claimedTips'

                                      Navigator.of(context)
                                          .pop(); // Close the input dialog

                                      // Display success dialog
                                      if (claimedTips == -1) {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return const AlertDialog(
                                              title: Text(
                                                "Oops!",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              content: Text(
                                                "You have no tips available :(",
                                                style: TextStyle(fontSize: 16),
                                                textAlign: TextAlign.center,
                                              ),
                                            );
                                          },
                                        );
                                      } else {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text(
                                                "Success",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                                textAlign: TextAlign.center,
                                              ),
                                              content: Text(
                                                "You have claimed \$${claimedTips.toStringAsFixed(2)} in tips!",
                                                style: const TextStyle(
                                                    fontSize: 16),
                                                textAlign: TextAlign.center,
                                              ),
                                              actions: [
                                                Center(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center, // Center the buttons horizontally
                                                    children: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(),
                                                        child: const Text(
                                                            "Close",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black)),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          debugPrint(
                                                              "More Info clicked");
                                                          // Placeholder function for More Info
                                                          showServerSignatureInfo();
                                                        },
                                                        child: const Text(
                                                            "More Info",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }
                                    } else {
                                      debugPrint(
                                          "Failed to submit request. Status code: ${response.statusCode}");

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              "Failed to submit claimTips request. Try again."),
                                        ),
                                      );
                                    }
                                  } catch (error) {
                                    debugPrint(
                                        "Error during HTTP request: $error");

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            "An error occurred while submitting the request."),
                                      ),
                                    );
                                  } finally {
                                    setState(() {
                                      isSubmitting =
                                          false; // Re-enable button after HTTP request
                                    });
                                  }
                                }
                              },
                        style: TextButton.styleFrom(
                          backgroundColor:
                              isSubmitting ? Colors.grey : Colors.green,
                        ),
                        child: const Text("Submit",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              ],
            );
          },
        );
      },
    ).then((_) {
      // Reset the button state when the dialog is closed
      setState(() {
        isSubmitting = false;
      });
    });
  }

  void showServerSignatureInfo() {
    const publicKey =
        'MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAqePMRYC7/28i9reLDqd77xHIuwHOEGL6sTO6MCSSrjNBJHH6xJnDPs8is3VyfbyZc01ql6H7k565W30OnGgkxBgPdAcaSySLm+G7MMJlviiw2jY6UmuEdOkA5e21GrOikQG3aBz1TtK4fbDL8R7wlKkHEpBzFLDRXHOlK3qyFVph3osU1bTB6nd+z5PRfRbJsUiOOXKJjUa7hXYQI6Z4PwasHDEWBy2HycdIRLdjOmlSjnsX22LsOo0/FEtF2VQU+CiDNXs1evBxDIi9JRMwwETq8L6y5EhRb8LlxpgL5sLaCyzyecyK3NIWwPsLJgOcJWDByUg2FWp/72UYp4mIutraXgEIcO0F/y4FViw8c38DN7V7SX0cUdYJdmkzByApQg0/s8D1krdrE3oyrP2BQ/s7x0SDT4QYt1hoeyZ2PKK6zjLG7nXhbWljhl3fehXuWXRDhcbkPCU0kBu7jk2nYuhRroPy5Brxc5ylwSNZZsqQxZMTxxh/n/T7zWMrdYXSbYsGjk8U6/W1Dru1f8LBMnSQNI8h7uWlv3/uSxsinUg3xeMl9AqPVugH8yGR8EJlJLEftpGmmjNBPtSIN3VWldvJ6NFWT0cX9rxyfT5oxeNScSJPwKUTKfFxC/mzW8KoDGsJjlg+ULFZxv2+5kgfR4XwJ9UxqfM+s6Z1c1CmjFMCAwEAAQ==';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('What is a Server Signature?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '''A digital signature (Server Signature) is a guarantee that only an entity with a private key (like Barzzy) can generate a message that validates for a public key. To verify:

1. Copy our permanent public key:
2. Go to https://8gwifi.org/RSAFunctionality?rsasignverifyfunctions=rsasignverifyfunctions&keysize=4096 or any other RSA signature verifier of your choice.
3. Click "Verify Signature"
4. Paste our permanent public key into the "Public Key" field. You may ignore the private key field. We do not intend to give this out.
5. Paste the "Receipt Verification Plaintext" from your email receipt into the "ClearText Message" field.
6. Paste the Digital Signature from your email receipt into the "Provide Signature Value (Base64)" field.
7. Select the "SHA256withRSA" option below.
8. You will see that page says "Signature Verification Passed". That means we generated the report!
9. If it says signature verification failed, try some of the steps below.
- Check options: Make sure you're on "Verify Signature", "4096 bit key", "SHA256withRSA"
- Check fields: Make sure you put the public key in the public key field, and the plaintext in the plaintext, and so on.
- Remove extra input: You may have inserted an extra line into the Plaintext Section. You should remove that if you may have put it in accidentally.
- Other websites: Our signature is in BASE64, key format is PEM, charset is UTF-8, and our plaintext is STRING.
- If it still says "Signature Verification Failed" then we didn't generate the report. You should inquire with the person who gave you the report as to where they got it from, because the report was clearly modified by a bad actor. If you got the report directly from emails ending with @barzzy.site, then send an inquiry to barzzy.llc@gmail.com explaining your issue, and forward the receipt email as well.''',
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: publicKey));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Public key copied to clipboard')),
                  );
                },
                child: const Text('Click to Copy Public Key'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
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

      // Send a message to initialize the bartender session
      final Map<String, dynamic> bartenderLogin = {
        'action': 'initialize',
        'barID': widget.barID,
        'bartenderID': widget.bartenderID
      };
      debugPrint("bartender id login");
      
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

          //debugPrint('Received: $event at ${DateTime.now()}');

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

            case 'orders':
              final List<dynamic> ordersJson = response['orders'];

              // Convert JSON to Order objects and update allOrders
              final incomingOrders = ordersJson
                  .map((json) => BartenderOrder.fromJson(json))
                  .toList();
              for (BartenderOrder incomingOrder in incomingOrders) {
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

                // Auto-claim the order if eligible
                if (incomingOrder.claimer.isEmpty &&
                    (incomingOrder.userId % bartenderCount) ==
                        bartenderNumber) {
                  final claimRequest = {
                    'action': 'claim',
                    'bartenderID': widget.bartenderID,
                    'userID': incomingOrder.userId,
                    'barID': widget.barID,
                  };

                  try {
                    socket!.sink.add(jsonEncode(claimRequest));
                    debugPrint(
                        "Auto-claimed order for user ID: ${incomingOrder.userId}");
                  } catch (e) {
                    debugPrint(
                        "Error auto-claiming order for user ID: ${incomingOrder.userId}: $e");
                  }
                }
              }
              _updateLists();
              break;

            case 'update':
              final List<dynamic> ordersJson = response['update'];

              // Convert JSON to Order objects and update allOrders
              final incomingOrders = ordersJson
                  .map((json) => BartenderOrder.fromJson(json))
                  .toList();
              for (BartenderOrder incomingOrder in incomingOrders) {
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
              _updateLists();
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

            case 'heartbeat':
              debugPrint('Still Alive');
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

  String formatElapsedTime(int seconds) {
    if (seconds < 0) {
      return "0m"; // Prevent negative minutes
    }

    int minutes = (seconds / 60).floor();
    return "$minutes m";
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    socket?.sink.close();
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}
