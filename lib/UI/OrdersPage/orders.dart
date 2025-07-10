import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:megrim/Backend/database.dart';
import 'package:megrim/Backend/cart.dart';
import 'package:megrim/Backend/websocket.dart';
import 'package:megrim/DTO/customerorder.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:megrim/DTO/transaction.dart';
import 'package:megrim/UI/AuthPages/RegisterPages/logincache.dart';
import 'package:megrim/config.dart';
import 'package:provider/provider.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => OrdersPageState();
}

class OrdersPageState extends State<OrdersPage> with WidgetsBindingObserver {
  late PageController _pageController; // Define a PageController
  int currentPage = 0;
  late double screenHeight;
  List<Transaction> transactionHistory = [];
  bool isHistoryLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(); // Initialize the controller
    WidgetsBinding.instance.addObserver(this);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final websocket = Provider.of<Websocket>(context, listen: false);
        websocket.sendRefreshMessage(context);
        _fetchTransactionHistory();
      }
    });
  }

  Future<void> _fetchTransactionHistory() async {
    setState(() => isHistoryLoading = true);

    try {
      final loginCache = Provider.of<LoginCache>(context, listen: false);
      final customerId = await loginCache.getUID();

      final response = await http.get(
        Uri.parse(
            '${AppConfig.postgresHttpBaseUrl}/customer/orders/$customerId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          transactionHistory = data.map((json) {
            return Transaction.fromJson(json);
          }).toList();
          isHistoryLoading = false;
        });
      } else {
        debugPrint(
            "Failed to fetch transaction history: ${response.statusCode}");
        setState(() => isHistoryLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching transaction history: $e");
      setState(() => isHistoryLoading = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenHeight = MediaQuery.of(context).size.height - (4 * kToolbarHeight);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: 2.0,
        title: Consumer<Websocket>(
          builder: (context, websocket, child) {
            final totalOrders = websocket.getOrders().length;

            // Determine the text based on the number of orders
            final displayText =
                totalOrders == 0 ? '0/0' : '${currentPage + 1} / $totalOrders';

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'O r d e r s',
                  style: GoogleFonts.megrim(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontSize: 25,
                  ),
                ),
                const Spacer(),
                Text(
                  displayText, // Display the appropriate text
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Consumer<Websocket>(
        builder: (context, websocket, child) {
          if (!websocket.isConnected) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            );
          }

          if (websocket.isLoading) {
            return const Center(
              child: SpinKitThreeBounce(
                color: Colors.white,
                size: 30.0,
              ),
            );
          }

          final orders = websocket.getOrders();

          return Consumer<LocalDatabase>(
            builder: (context, localDatabase, child) {
              return RefreshIndicator(
                  onRefresh: () => _refreshOrders(context),
                  color: Colors.black,
                  child: orders.length > 1 // Check if there are multiple orders
                      ? PageView.builder(
                          controller: _pageController,
                          scrollDirection: Axis.vertical,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: orders.length,
                          onPageChanged: (index) {
                            setState(() {
                              currentPage = index;
                            });
                          },
                          itemBuilder: (context, verticalIndex) {
                            final pair =
                                orders[verticalIndex]; // MapEntry<int, int>
                            final merchantId = pair.key;
                            final employeeId = pair.value;
                            final order =
                                localDatabase.getOrderForMerchantAndEmployee(
                                    merchantId, employeeId);

                            return PageView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                order != null
                                    ? _buildOrderCard(order)
                                    : const Center(
                                        child: Text(
                                          'No active orders',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                          ),
                                        ),
                                      ),
                                _buildTransactionHistory(),
                              ],
                            );
                          },
                        )
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: screenHeight,
                            child: PageView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                orders.isNotEmpty &&
                                        localDatabase
                                                .getOrderForMerchantAndEmployee(
                                                    orders.first.key,
                                                    orders.first.value) !=
                                            null
                                    ? _buildOrderCard(localDatabase
                                        .getOrderForMerchantAndEmployee(
                                            orders.first.key,
                                            orders.first.value)!)
                                    : Center(
                                        child: Text(
                                          'No active orders',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                          ),
                                        ),
                                      ),
                                _buildTransactionHistory(),
                              ],
                            ),
                          )));
            },
          );
        },
      ),
    );
  }

  Future<void> _refreshOrders(BuildContext context) async {
    final websocket = Provider.of<Websocket>(context, listen: false);
    websocket.sendRefreshMessage(context);
    _fetchTransactionHistory();
    debugPrint('Order list has been refreshed.');
  }

  Widget _buildTransactionHistory() {
    if (isHistoryLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (transactionHistory.isEmpty) {
      return const Center(
        child: Text(
          'No past orders',
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactionHistory.length,
      itemBuilder: (context, index) {
        final order = transactionHistory[index];

        // Merge items with the same name regardless of payment type
        final Map<String, int> mergedItems = {};
        for (var item in order.items) {
          mergedItems.update(
            item.itemName,
            (existingQty) => existingQty + item.quantity,
            ifAbsent: () => item.quantity,
          );
        }

        final hasPoints =
            order.items.any((item) => item.paymentType == 'points');
        final hasRegular =
            order.items.any((item) => item.paymentType == 'regular');
        final paymentTypeSummary = (hasPoints && hasRegular)
            ? 'Payment: Mixed'
            : hasPoints
                ? 'Payment: Points'
                : 'Payment: Regular';

        // Format timestamp inline
        String formattedTimestamp;
        try {
          final dateTime = DateTime.parse(order.timestamp);
          formattedTimestamp =
              '${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
        } catch (_) {
          formattedTimestamp = order.timestamp;
        }

        final merchant = LocalDatabase.getMerchantById(order.merchantId);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Row(
                      children: [
                        if (order.totalRegularPrice > 0)
                          Text(
                            '\$${order.totalRegularPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (order.totalRegularPrice > 0 &&
                            order.totalPointPrice > 0)
                          Text(
                            ', ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (order.totalPointPrice > 0)
                          Text(
                            '${order.totalPointPrice} pts',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      order.status == 'delivered'
                          ? 'COMPLETED'
                          : order.status == 'canceled'
                              ? 'CANCELED'
                              : order.status.toUpperCase(),
                      style: TextStyle(
                        color: order.status == 'delivered'
                            ? Colors.lightGreenAccent
                            : Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...mergedItems.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${entry.key} x${entry.value}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    )),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      formattedTimestamp,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '@${merchant?.nickname ?? "Unknown"}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(CustomerOrder order) {
    final merchant = LocalDatabase.getMerchantById(order.merchantId);

    final employee = Provider.of<LocalDatabase>(context, listen: false)
        .findEmployeeById(order.merchantId, order.employeeId);

    // Use employee image if it exists, otherwise fallback
    final String imageUrl =
        (employee?.imageUrl != null && employee!.imageUrl!.isNotEmpty)
            ? employee.imageUrl!
            : 'https://www.barzzy.site/images/default.png';

    final String workerName =
        (employee?.name?.isNotEmpty ?? false) ? employee!.name! : 'Loading...';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 1),
          Column(
            children: [
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: 100,
                  height: 100,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "@${merchant?.nickname ?? 'No Tag'}",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                workerName,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 21,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          _buildStatusBar(order.status),
          const SizedBox(height: 10),
          Row(
            children: [
              const Spacer(),
              // Column(
              //   mainAxisAlignment: MainAxisAlignment.start,
              //   children: [
              //     Text(
              //       '${order.name}',
              //       style: const TextStyle(
              //         color: Colors.white,
              //         fontSize: 21,
              //         fontWeight: FontWeight.bold,
              //       ),
              //     ),
              //     //const SizedBox(height: 5),
              //     // Text(
              //     //   '$workerName',
              //     //   style: const TextStyle(
              //     //     color: Colors.grey,
              //     //     fontSize: 21,
              //     //   ),
              //     // ),
              //   ],
              // ),
              const Spacer(),
            ],
          ),
          _buildItemsGrid(order.items),
          const Spacer(flex: 2),
          _buildBottomButton(order),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildStatusBar(String status) {
    // Define colors and icons for each stage
    Color inactiveColor = Colors.grey;
    Color inQueueColor = Colors.orange;
    Color readyColor = Colors.lightGreenAccent;
    Color arrivedColor = Colors.blueAccent;

    IconData inQueueIcon = Icons.access_time;
    IconData readyIcon = Icons.check_circle;

    bool isInQueue = status == "unready";
    bool isReady = status == "ready";
    bool isArrived = status == "arrived";
    bool isDeliveredOrCanceled =
        (status == "delivered" || status == "canceled");

    if (isDeliveredOrCanceled) {
      return ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor:
              status == "delivered" ? Colors.grey : Colors.red.shade300,
        ),
        child: Text(
          status == "delivered" ? "Delivered" : "Canceled",
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
        ),
      );
    }

    Color queueColor;

    Color readyStageColor;
    Color firstConnectorColor;
    Color secondConnectorColor;

    if (isReady) {
      queueColor = readyColor;
      readyStageColor = readyColor;
      firstConnectorColor = readyColor;
      secondConnectorColor = readyColor;
    } else if (isInQueue) {
      queueColor = inQueueColor;
      readyStageColor = inactiveColor;
      firstConnectorColor = inactiveColor;
      secondConnectorColor = inactiveColor;
    } else if (isArrived) {
      queueColor = arrivedColor;
      readyStageColor = arrivedColor;
      firstConnectorColor = arrivedColor;
      secondConnectorColor = arrivedColor;
    } else {
      queueColor = inactiveColor;
      readyStageColor = inactiveColor;
      firstConnectorColor = inactiveColor;
      secondConnectorColor = inactiveColor;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            Icon(
              inQueueIcon,
              color: queueColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              "In Queue",
              style: TextStyle(
                fontSize: 12,
                color: queueColor,
              ),
            ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 15.0),
            child: Container(
              height: 2,
              color: firstConnectorColor,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 15.0),
            child: Container(
              height: 2,
              color: secondConnectorColor,
            ),
          ),
        ),
        Column(
          children: [
            Icon(
              readyIcon,
              color: readyStageColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              "Ready",
              style: TextStyle(
                fontSize: 12,
                color: readyStageColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsGrid(List<ItemOrder> items) {
    const itemsPerPage = 6; // Maximum items per page
    final Map<String, MapEntry<String, int>> mergedItems = {};
    for (var item in items) {
      final String key = '${item.itemId}';
      mergedItems.update(
        key,
        (existingEntry) =>
            MapEntry(item.itemName, existingEntry.value + item.quantity),
        ifAbsent: () => MapEntry(item.itemName, item.quantity),
      );
    }

    final List<MapEntry<String, MapEntry<String, int>>> itemList =
        mergedItems.entries.toList();
    final totalPages = (itemList.length / itemsPerPage).ceil();

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            const SizedBox(height: 10),
            if (totalPages > 1)
              Text(
                '${currentPage + 1} / $totalPages', // Current page / Total pages
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 25),
            SizedBox(
              height: items.length <= 3 ? 62 : 125,
              child: PageView.builder(
                itemCount: totalPages,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index; // Update the current page
                  });
                },
                itemBuilder: (context, pageIndex) {
                  // Get the items for the current page
                  final startIndex = pageIndex * itemsPerPage;
                  final endIndex =
                      (startIndex + itemsPerPage).clamp(0, itemList.length);
                  final pageItems = itemList.sublist(startIndex, endIndex);

                  // If there's 1 or 2 items, center them manually
                  if (pageItems.length <= 2) {
                    return Center(
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: pageItems.map((entry) {
                          final itemData = entry.value;
                          final itemName = itemData.key;
                          final quantity = itemData.value;
                          return Container(
                            width: 110,
                            height: 60,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  itemName,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'x$quantity',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }

                  // Default grid view for more than 2 items
                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 3 items per row
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      childAspectRatio: 2.0,
                    ),
                    itemCount: pageItems.length,
                    itemBuilder: (context, index) {
                      final entry = pageItems[index];
                      final itemData = entry.value;
                      final itemName = itemData.key;
                      final quantity = itemData.value;

                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              itemName,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'x$quantity',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomButton(CustomerOrder order) {
    debugPrint("Rendering order with status: '${order.status}'");
    Color activeColor;
    if (order.status == "ready") {
      activeColor = Colors.lightGreenAccent;
    } else if (order.status == "arrived") {
      activeColor = Colors.blueAccent;
    } else if (order.status == "unready") {
      activeColor = Colors.orange;
    } else {
      activeColor = Colors.grey;
    }

    if (order.status == "unready") {
      return Center(
        child: SizedBox(
          height: 40,
          child: Text(
            "Your order is now in queue",
            style: GoogleFonts.poppins(
              color: activeColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (order.status == "ready") {
      return Center(child: _buildArriveButton(order));
    } else if (order.status == "arrived") {
      return Center(
        child: SizedBox(
          height: 40,
          child: Text(
            'Worker has been notified',
            style: GoogleFonts.poppins(
              color: activeColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  Widget _buildReorderButton(CustomerOrder order) {
    return GestureDetector(
      onTap: () async {
        final merchantId = order.merchantId;
        final cart = Cart();
        cart.setMerchant(merchantId);

        // Use the reorder method to reset the cart based on the order
        cart.reorder(order);

        // Navigate to MenuPage
        await Navigator.of(context).pushNamed(
          '/items',
          arguments: {
            'merchantId': merchantId,
            'cart': cart,
            'itemId': order.items.first.itemId, // Optional itemId.
          },
        );
      },
      child: Container(
        height: 50,
        width: 200,
        //padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            "Reorder",
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArriveButton(CustomerOrder order) {
    return GestureDetector(
      onTap: () {
        final merchantId = order.merchantId;
        final employeeId = order.employeeId;

        final websocket = Provider.of<Websocket>(context, listen: false);
        websocket.sendArriveMessage(merchantId, employeeId);

        debugPrint('Arrive message sent for merchantId: $merchantId');
      },
      child: Container(
        height: 50,
        width: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            "I'm Here",
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshOrders(context);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // ✅ Remove observer
    _pageController.dispose();
    super.dispose();
  }
}
