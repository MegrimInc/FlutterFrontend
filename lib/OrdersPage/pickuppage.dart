import 'package:barzzy/MenuPage/cart.dart';
import 'package:barzzy/OrdersPage/websocket.dart';
import 'package:barzzy/Backend/customer_order.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:barzzy/Backend/localdatabase.dart';

class PickupPage extends StatefulWidget {
  const PickupPage({super.key});

  @override
  State<PickupPage> createState() => PickupPageState();
}

class PickupPageState extends State<PickupPage> with WidgetsBindingObserver {
  late PageController _pageController; // Define a PageController
  int currentPage = 0;
  late double screenHeight;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(); // Initialize the controller
    WidgetsBinding.instance.addObserver(this);

    Future.delayed(const Duration(milliseconds: 500), () {
    if (mounted) {
      final hierarchy = Provider.of<Hierarchy>(context, listen: false);
      hierarchy.sendRefreshMessage(context); 
    }
  });

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenHeight = MediaQuery.of(context).size.height - (4 * kToolmerchantHeight);
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
        title: Consumer<Hierarchy>(
          builder: (context, hierarchy, child) {
            final totalOrders = hierarchy.getOrders().length;

            // Determine the text based on the number of orders
            final displayText =
                totalOrders == 0 ? '...' : '${currentPage + 1} / $totalOrders';

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'O R D E R S',
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
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Consumer<Hierarchy>(
        builder: (context, hierarchy, child) {
          if (!hierarchy.isConnected) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            );
          }

          if (hierarchy.isLoading) {
            return const Center(
              child: SpinKitThreeBounce(
                color: Colors.white,
                size: 30.0,
              ),
            );
          }

          final orders = hierarchy.getOrders();

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
                            final merchantId = orders[verticalIndex];
                            final order = localDatabase.getOrderForMerchant(merchantId);

                            if (order == null) {
                              return const Center(
                                child: Text(
                                  'No orders found',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                  ),
                                ),
                              );
                            }

                            return _buildOrderCard(order);
                          },
                        )
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                              height:
                                  screenHeight, // Use the class variable here
                              child: orders.isNotEmpty &&
                                      localDatabase
                                              .getOrderForMerchant(orders.first) !=
                                          null
                                  ? _buildOrderCard(localDatabase
                                      .getOrderForMerchant(orders.first)!)
                                  : const Center(
                                      child: Text(
                                        'No orders found.',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                        ),
                                      ),
                                    )),
                        ));
            },
          );
        },
      ),
    );
  }

  Future<void> _refreshOrders(BuildContext context) async {
    final hierarchy = Provider.of<Hierarchy>(context, listen: false);
    hierarchy.sendRefreshMessage(context);
    debugPrint('Order list has been refreshed.');
  }

  Widget _buildOrderCard(CustomerOrder order) {
    final merchant = LocalDatabase.getMerchantById(order.merchantId);

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
                  imageUrl: merchant?.tagimg ??
                      'https://www.barzzy.site/images/default.png',
                  fit: BoxFit.cover,
                  width: 100,
                  height: 100,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                merchant?.name ?? 'No Tag',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          _buildStatusBar(order.status, order.claimer),
          const SizedBox(height: 25),
          Row(
            children: [
              const Spacer(),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    '*${order.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    ' Worker: ${order.claimer.isNotEmpty ? order.claimer : 'N/A'}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 21,
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
          const Spacer(flex: 1),
          _buildItemsGrid(order.items),
          const Spacer(flex: 2),
          _buildBottomButton(order),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildStatusBar(String status, String claimer) {
    // Define colors and icons for each stage
    Color inactiveColor = Colors.grey;
    Color inQueueColor = Colors.orange;
    Color claimedColor = Colors.yellow.shade400;
    Color readyColor = Colors.lightGreenAccent;
    Color arrivedColor = Colors.blueAccent;

    IconData inQueueIcon = Icons.access_time;
    IconData claimedIcon = Icons.wine_bar;
    IconData readyIcon = Icons.check_circle;

    bool isInQueue = status == "unready" && claimer.isEmpty;
    bool isClaimed = status == "unready" && claimer.isNotEmpty;
    bool isReady = status == "ready" && claimer.isNotEmpty;
    bool isArrived = status == "arrived" && claimer.isNotEmpty;
    bool isDeliveredOrCanceled =
        (status == "delivered" || status == "canceled") && claimer.isNotEmpty;

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
    Color claimedStageColor;
    Color readyStageColor;
    Color firstConnectorColor;
    Color secondConnectorColor;

    if (isReady) {
      queueColor = readyColor;
      claimedStageColor = readyColor;
      readyStageColor = readyColor;
      firstConnectorColor = readyColor;
      secondConnectorColor = readyColor;
    } else if (isClaimed) {
      queueColor = claimedColor;
      claimedStageColor = claimedColor;
      readyStageColor = inactiveColor;
      firstConnectorColor = claimedColor;
      secondConnectorColor = inactiveColor;
    } else if (isInQueue) {
      queueColor = inQueueColor;
      claimedStageColor = inactiveColor;
      readyStageColor = inactiveColor;
      firstConnectorColor = inactiveColor;
      secondConnectorColor = inactiveColor;
    } else if (isArrived) {
      queueColor = arrivedColor;
      claimedStageColor = arrivedColor;
      readyStageColor = arrivedColor;
      firstConnectorColor = arrivedColor;
      secondConnectorColor = arrivedColor;
    } else {
      queueColor = inactiveColor;
      claimedStageColor = inactiveColor;
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
        Column(
          children: [
            Icon(
              claimedIcon,
              color: claimedStageColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              "Preparing",
              style: TextStyle(
                fontSize: 12,
                color: claimedStageColor,
              ),
            ),
          ],
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Spacer(),
                  Text(
                    '${currentPage + 1} / $totalPages', // Current page / Total pages
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 25),
                ],
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
    Color activeColor;
    if (order.status == "ready" && order.claimer.isNotEmpty) {
      activeColor = Colors.lightGreenAccent;
    } else if (order.status == "arrived" && order.claimer.isNotEmpty) {
      activeColor = Colors.blueAccent;
    } else if (order.status == "unready" && order.claimer.isNotEmpty) {
      activeColor = Colors.yellow.shade400;
    } else if (order.status == "unready" && order.claimer.isEmpty) {
      activeColor = Colors.orange;
    } else {
      activeColor = Colors.grey;
    }

    if ((order.status == "delivered" || order.status == "canceled") &&
        order.claimer.isNotEmpty) {
      return Center(child: _buildReorderButton(order));
    } else if (order.status == "unready" && order.claimer.isEmpty) {
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
    } else if (order.status == "unready" && order.claimer.isNotEmpty) {
      return Center(
        child: SizedBox(
          height: 40,
          child: Text(
            'Your order is being prepared',
            style: GoogleFonts.poppins(
              color: activeColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (order.status == "ready" && order.claimer.isNotEmpty) {
      return Center(child: _buildArriveButton(order));
    } else if (order.status == "arrived" && order.claimer.isNotEmpty) {
      return Center(
        child: SizedBox(
          height: 40,
          child: Text(
            'Worker ${order.claimer} has been notified',
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
          '/menu',
          arguments: {
            'merchantId': merchantId,
            'cart': cart,
            'itemId':
                order.items.first.itemId.toString(), // Optional itemId.
          },
        );
      },
      child: Container(
        height: 50,
        width: 300,
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
        final merchantIdString = order.merchantId;

        // Convert merchantId to int
        final int merchantId =
            int.tryParse(merchantIdString) ?? -1; // Fallback to -1 if parsing fails

        if (merchantId != -1) {
          // Send the arrive message
          final hierarchy = Provider.of<Hierarchy>(context, listen: false);
          hierarchy.sendArriveMessage(merchantId);

          debugPrint('Arrive message sent for merchantId: $merchantId');
        } else {
          debugPrint('Failed to parse merchantId: $merchantIdString');
        }
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