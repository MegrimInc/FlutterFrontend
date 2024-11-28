// ignore_for_file: use_build_context_synchronously

import 'dart:async'; // Import the async package for Timer
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:barzzy/Backend/bartender_order.dart';
import 'package:barzzy/Terminal/stationid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  List<BartenderOrder> allOrders = [];
  List<BartenderOrder> readyOrders = [];
  List<BartenderOrder> otherOrders = [];
  int index = 0;
  //TESTING VARIABLE
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
  WebSocket? websocket;

  void claimTips() {
    bool isSubmitting = false; // Track button status within the dialog

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
                '           Claim tips for ${widget.bartenderID}            ',
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
                                isSubmitting = true; // Temporarily disable button
                              });
                  
                              const String url =
                                  "http://34.230.32.169:8080/orders/claim";
                  
                              try {
                                final response = await http.post(
                                  Uri.parse(url),
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode(request),
                                );
                  
                                if (response.statusCode == 200) {
                                  debugPrint(
                                      "Successfully submitted request for claimTips");
                                  final responseData = jsonDecode(response.body);
                  
                                  final double claimedTips = double.parse(responseData
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
                                                fontWeight: FontWeight.bold),
                                                 textAlign: TextAlign.center,
                                          ),
                                          content: Text(
                                            "You have claimed \$${claimedTips.toStringAsFixed(2)} in tips!",
                                            style: const TextStyle(fontSize: 16),
                                             textAlign: TextAlign.center,
                                          ),
                                          actions: [
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center, // Center the buttons horizontally
                        children: [
                          TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text("Close",
                                              style: TextStyle(color: Colors.black)
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                debugPrint("More Info clicked");
                                                // Placeholder function for More Info
                                                showServerSignatureInfo();
                                              },
                                              child: const Text("More Info", 
                                              style: TextStyle(color: Colors.black)
                                            ),
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
                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Failed to submit claimTips request. Try again."),
                                    ),
                                  );
                                }
                              } catch (error) {
                                debugPrint("Error during HTTP request: $error");
                  
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
                      backgroundColor: isSubmitting ? Colors.grey : Colors.green,
                    ),
                    child: const Text("Submit",
                        style: TextStyle(color: Colors.white)),
                  ),
                  ],),
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

    if (testing) {
      allOrders = [
        BartenderOrder(
            '1',
            101,
            20.50,
            3.00,
            true,
            [
              DrinkOrder(1, 'Mojito', 'regular', 'single', 1),
              DrinkOrder(2, 'Whiskey Sour', 'regular', 'double', 2),
            ],
            'claimed',
            'A',
            1678901234000,
            'session_001',
            'Unnamed'),
        BartenderOrder(
            '2',
            102,
            35.75,
            5.25,
            false,
            [
              DrinkOrder(3, 'Old Fashioned', 'regular', 'single', 1),
              DrinkOrder(4, 'Martini', 'points', 'double', 1),
            ],
            'claimed',
            'D',
            1678901235000,
            'session_002',
            'Michael Bay'),
        BartenderOrder(
            '3',
            103,
            50.00,
            8.00,
            true,
            [
              DrinkOrder(5, 'Gin and Tonic', 'regular', 'single', 3),
              DrinkOrder(6, 'Cosmopolitan', 'regular', 'double', 1),
            ],
            'open',
            '',
            1678901236000,
            'session_003',
            'John Doe'),
        BartenderOrder(
            '4',
            104,
            40.00,
            6.50,
            false,
            [
              DrinkOrder(7, 'Margarita', 'points', 'double', 2),
              DrinkOrder(7, 'Margarita', 'points', 'double', 2),
              DrinkOrder(7, 'Margarita', 'points', 'double', 2),
              DrinkOrder(7, 'Margarita', 'points', 'double', 2),
              DrinkOrder(7, 'Margarita', 'points', 'double', 2),
            ],
            'open',
            '',
            1678901237000,
            'session_004',
            'Kermit'),
        BartenderOrder(
            '5',
            105,
            30.00,
            4.50,
            true,
            [
              DrinkOrder(8, 'Daiquiri', 'regular', 'single', 1),
              DrinkOrder(9, 'Negroni', 'regular', 'double', 1),
            ],
            'ready',
            'X',
            1678901238000,
            'session_005',
            'James bond'),
        BartenderOrder(
            '6',
            106,
            25.00,
            3.75,
            false,
            [
              DrinkOrder(10, 'Long Island Iced Tea', 'points', 'single', 2),
            ],
            'arrived',
            'A',
            1678901239000,
            'session_006',
            'Alexandria Oscasio-Cortez'),
        BartenderOrder(
            '7',
            107,
            60.00,
            10.00,
            true,
            [
              DrinkOrder(11, 'Screwdriver', 'regular', 'double', 1),
              DrinkOrder(12, 'Pina Colada', 'points', '', 1),
              DrinkOrder(13, 'Bloody Mary', 'regular', 'double', 1),
            ],
            'open',
            '',
            1678901240000,
            'session_007',
            'Donald Trump'),
        BartenderOrder(
            '1',
            101,
            20.50,
            3.00,
            true,
            [
              DrinkOrder(1, 'Mojito', 'regular', 'single', 1),
              DrinkOrder(2, 'Whiskey Sour', 'regular', 'double', 2),
            ],
            'claimed',
            'A',
            1678901234000,
            'session_001',
            'here'),
        BartenderOrder(
            '2',
            102,
            35.75,
            5.25,
            false,
            [
              DrinkOrder(3, 'Old Fashioned', 'regular', 'single', 1),
              DrinkOrder(4, 'Martini', 'points', 'double', 1),
            ],
            'claimed',
            'D',
            1678901235000,
            'session_002',
            'arrived at Bay'),
        BartenderOrder(
            '3',
            103,
            50.00,
            8.00,
            true,
            [
              DrinkOrder(5, 'Gin and Tonic', 'regular', 'single', 3),
              DrinkOrder(6, 'Cosmopolitan', 'regular', 'double', 1),
            ],
            'open',
            '',
            1678901236000,
            'session_003',
            'look up'),
        BartenderOrder(
            '4',
            104,
            40.00,
            6.50,
            false,
            [
              DrinkOrder(7, 'Margarita', 'points', 'double', 2),
              DrinkOrder(7, 'Margarita', 'points', 'double', 2),
              DrinkOrder(7, 'Margarita', 'points', 'double', 2),
              DrinkOrder(7, 'Margarita', 'points', 'double', 2),
              DrinkOrder(7, 'Margarita', 'points', 'double', 2),
            ],
            'open',
            '',
            1678901237000,
            'session_004',
            'give me '),
        BartenderOrder(
            '5',
            105,
            30.00,
            4.50,
            true,
            [
              DrinkOrder(8, 'Daiquiri', 'regular', 'single', 1),
              DrinkOrder(9, 'Negroni', 'regular', 'double', 1),
            ],
            'ready',
            'X',
            1678901238000,
            'session_005',
            'imatthelocationsothatswhyyoushouldgiveittome'),
        BartenderOrder(
            '6',
            106,
            25.00,
            3.75,
            false,
            [
              DrinkOrder(10, 'Long Island Iced Tea', 'points', 'single', 2),
            ],
            'open',
            '',
            1678901239000,
            'session_006',
            'here'),
        BartenderOrder(
            '7',
            107,
            60.00,
            10.00,
            true,
            [
              DrinkOrder(11, 'Screwdriver', 'regular', 'double', 1),
              DrinkOrder(12, 'Pina Colada', 'points', '', 1),
              DrinkOrder(13, 'Bloody Mary', 'regular', 'double', 1),
            ],
            'open',
            '',
            1678901240000,
            'session_007',
            'here'),
      ];
    }

    _updateLists();
  }

  void _updateLists() {
    debugPrint("Starting _updateLists...");

    debugPrint("All Orders:");
    for (var order in allOrders) {
      debugPrint(
          "Order ID: ${order.userId}, Status: ${order.status}, Claimer: ${order.claimer}");
    }

    setState(() {
      // Separate "arrived" orders
      List<BartenderOrder> arrivedOrders =
          allOrders.where((order) => order.status == 'arrived').toList();
      debugPrint("Arrived Orders Count: ${arrivedOrders.length}");

      // Separate claimed and unclaimed orders, excluding "arrived" orders
      List<BartenderOrder> claimedOrders = allOrders
          .where((order) =>
              order.claimer == widget.bartenderID && order.status != 'arrived')
          .toList();
      debugPrint("Claimed Orders Count: ${claimedOrders.length}");

      List<BartenderOrder> unclaimedOrders = allOrders
          .where((order) =>
              order.claimer != widget.bartenderID && order.status != 'arrived')
          .toList();
      debugPrint("Unclaimed Orders Count: ${unclaimedOrders.length}");

      // Sort each category by timestamp (older first)
      arrivedOrders.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      claimedOrders.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      unclaimedOrders.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      debugPrint("Sorted orders by timestamp.");

      // Combine sorted lists
      List<BartenderOrder> sortedOrders = [
        ...arrivedOrders,
        ...claimedOrders,
        ...unclaimedOrders,
      ];
      debugPrint("Total Sorted Orders Count: ${sortedOrders.length}");

      // Precompute lists for "ready" and "other" orders
      readyOrders = sortedOrders
          .where(
              (order) => order.status == 'ready' || order.status == 'arrived')
          .toList();
      debugPrint("Ready Orders Count: ${readyOrders.length}");

      otherOrders = sortedOrders
          .where(
              (order) => order.status != 'ready' || order.status == 'arrived')
          .toList();
      debugPrint("Other Orders Count: ${otherOrders.length}");

      // Apply the "Your Orders Only" filter to both lists if filterUnique is true
      if (filterUnique) {
        readyOrders = readyOrders
            .where((order) =>
                order.claimer == widget.bartenderID ||
                (order.claimer.isEmpty &&
                    (order.userId % bartenderCount) == bartenderNumber))
            .toList();
        debugPrint("Filtered Ready Orders Count: ${readyOrders.length}");

        otherOrders = otherOrders
            .where((order) =>
                order.claimer == widget.bartenderID ||
                (order.claimer.isEmpty &&
                    (order.userId % bartenderCount) == bartenderNumber))
            .toList();
        debugPrint("Filtered Other Orders Count: ${otherOrders.length}");
      }

      // Handle terminal disablement logic
    if (disabledTerminal &&
        !allOrders.any((order) => order.claimer == widget.bartenderID)) {
      socket!.sink.add(
        json.encode({
          'action': 'dispose',
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
    readyOrders.clear();
    otherOrders.clear();

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
    debugPrint('USER ID: ${order.userId}, Age: $ageInSeconds seconds');
    if (order.claimer != '' && order.claimer != widget.bartenderID) {
      return Colors.grey[700]!;
    }

    if (order.status == 'ready') return Colors.green;
    if (order.status == 'arrived') return Colors.blueAccent;
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize
                      .min, // Keeps the Row compact around its children
                  children: [
                    Icon(
                      Icons.circle,
                      color: index == 0
                          ? Colors.white
                          : Colors.grey, // Blue for index 0, grey otherwise
                      size: 12.0,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.circle,
                      color: index == 0
                          ? Colors.grey
                          : Colors.white, // Grey for index 0, blue otherwise
                      size: 12.0,
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: claimTips,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text("Claim Tips"),
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
      body: PageView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 2, // Number of pages (e.g., unpaid, paid)
        onPageChanged: (pageIndex) {
          setState(() {
            index = pageIndex; // Update the index when the page changes
            debugPrint("Page changed to: $index");
          });
        },
        itemBuilder: (context, pageIndex) {
          final displayList = pageIndex == 0 ? otherOrders : readyOrders;
          return RefreshIndicator(
            onRefresh: () async {
              _refresh(); // Call your existing refresh method
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ListView.builder(
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  final order = displayList[index];
                  final tintColor = _getOrderTintColor(order);

                  final unpaidDrinks = order.drinks.where((drink) {
                    return drink.paymentType.toLowerCase() == "regular" &&
                        !order.inAppPayments;
                  }).toList();

                  final paidDrinks = order.drinks.where((drink) {
                    return !(drink.paymentType.toLowerCase() == "regular" &&
                        !order.inAppPayments);
                  }).toList();

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
                          const SizedBox(height: 10),
                          Row(children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Text(
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
                            ),
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Text(
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
                            ),
                          ]),
                          IntrinsicHeight(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  // Left side: Claimer or Loading Indicator
                                  order.claimer.isEmpty
                                      ? const SpinKitThreeBounce(
                                          color: Colors.white,
                                          size: 30.0,
                                        )
                                      : Text(
                                          '@${order.claimer}',
                                          style: const TextStyle(
                                            fontSize: 30,
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
                                  // Middle: Unpaid and Paid sections
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              const Text(
                                                'UNPAID ❗',
                                                style: TextStyle(
                                                  fontSize: 20,
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
                                              ),
                                              ...unpaidDrinks.map((drink) =>
                                                  Text(
                                                    formatDrink(drink),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.white,
                                                      shadows: [
                                                        Shadow(
                                                          color: Colors.black,
                                                          offset:
                                                              Offset(1.0, 1.0),
                                                          blurRadius: 1.0,
                                                        ),
                                                      ],
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  )),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 1,
                                          color: Colors.white,
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              const Text(
                                                'PAID ✔️',
                                                style: TextStyle(
                                                  fontSize: 20,
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
                                              ),
                                              ...paidDrinks.map((drink) => Text(
                                                    formatDrink(drink),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.white,
                                                      shadows: [
                                                        Shadow(
                                                          color: Colors.black,
                                                          offset:
                                                              Offset(1.0, 1.0),
                                                          blurRadius: 1.0,
                                                        ),
                                                      ],
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  )),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Text(
                                    formatElapsedTime(order
                                        .getAge()), // Use the getAge method
                                    style: const TextStyle(
                                      fontSize: 30,
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
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
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
              }
              setState(() {
                // Update the displayList based on the new allOrders
                _updateLists();
              });
              break;

            case 'sessionId': // Somebody changed up how orders are sent back. They changed it so that orders are sent back as {Order} instead of {orders:[Order1, Order2...]}
              // Parse the response directly into a BartenderOrder object
              final incomingOrder = BartenderOrder.fromJson(response);

              // Check if the order exists in allOrders
              int index = allOrders
                  .indexWhere((order) => order.userId == incomingOrder.userId);
              if (index != -1) {
                // If it exists, replace the old order
                allOrders[index] = incomingOrder;
                if (allOrders[index].status == 'delivered' ||
                    allOrders[index].status == 'canceled') {
                  allOrders.removeAt(index);
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

  String formatElapsedTime(int seconds) {
    int minutes = (seconds / 60).floor(); // Convert seconds to minutes
    return "${minutes}m";
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }
}
