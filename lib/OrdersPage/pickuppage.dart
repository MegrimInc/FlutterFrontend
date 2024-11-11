import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:barzzy/OrdersPage/hierarchy.dart';
import 'package:barzzy/Backend/activeorder.dart';
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

class PickupPageState extends State<PickupPage> {
  late PageController _pageController; // Define a PageController

  @override
  void initState() {
    super.initState();
    _pageController = PageController(); // Initialize the controller
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
        title: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Orders',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
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
          final orders = hierarchy.getOrders();
            
          return Consumer<LocalDatabase>(
            builder: (context, localDatabase, child) {
              return RefreshIndicator(
                onRefresh: () => _refreshOrders(context),
                color: Colors.black,
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: orders.length,
                  itemBuilder: (context, verticalIndex) {
                    final barId = orders[verticalIndex];
                    final order = localDatabase.getOrderForBar(barId);
            
            
                     if (orders.isEmpty || order == null) {
              return const Center(
                child: Text(
                  'No orders have been placed yet.',
                  style: TextStyle(color: Colors.white, fontSize: 17),
                ),
              );
            }
            
            
                    return _buildOrderCard(order);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.3),
            width: 0.2078,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Orders',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshOrders(BuildContext context) async {
    final hierarchy = Provider.of<Hierarchy>(context, listen: false);
    hierarchy.sendRefreshMessage(context);
    debugPrint('Order list has been refreshed.');
  }

  Widget _buildOrderCard(CustomerOrder order) {
    final bar = LocalDatabase.getBarById(order.barId);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 45),
          Column(
            children: [
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: bar?.tagimg ??
                      'https://www.barzzy.site/images/default.png',
                  fit: BoxFit.cover,
                  width: 100,
                  height: 100,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                bar?.name ?? 'No Tag',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 35),
          _buildStatusBar(order.status, order.claimer),
          const SizedBox(height: 35),
          Row(
            children: [
              const Spacer(),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.userId}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Station: ${order.claimer.isNotEmpty ? order.claimer : 'N/A'}',
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
          const SizedBox(height: 25),
          const Divider(color: Colors.white, thickness: .25),
          const Spacer(),
          Column(
            children: order.drinks.map((drinkOrder) {
              return Text(
                '${drinkOrder.drinkName} x ${drinkOrder.quantity}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          _buildBottomButton(order),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildStatusBar(String status, String claimer) {
    // Define colors and icons for each stage
    Color inactiveColor = Colors.grey;
    Color inQueueColor = Colors.orange;
    Color claimedColor = Colors.yellow;
    Color readyColor = Colors.green;

    IconData inQueueIcon = Icons.access_time;
    IconData claimedIcon = Icons.directions_run;
    IconData readyIcon = Icons.check_circle;

    bool isInQueue = status == "unready" && claimer.isEmpty;
    bool isClaimed = status == "unready" && claimer.isNotEmpty;
    bool isReady = status == "ready" && claimer.isNotEmpty;
    bool isDeliveredOrCanceled =
        (status == "delivered" || status == "canceled") && claimer.isNotEmpty;

    if (isDeliveredOrCanceled) {
      return ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[700],
        ),
        child: Text(
          status == "delivered" ? "Delivered" : "Canceled",
          style: const TextStyle(
            color: Colors.white,
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
              "Claimed",
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

  Widget _buildBottomButton(CustomerOrder order) {
    Color activeColor;
    if (order.status == "ready" && order.claimer.isNotEmpty) {
      activeColor = Colors.green;
    } else if (order.status == "unready" && order.claimer.isNotEmpty) {
      activeColor = Colors.yellow;
    } else if (order.status == "unready" && order.claimer.isEmpty) {
      activeColor = Colors.orange;
    } else {
      activeColor = Colors.grey;
    }

    if ((order.status == "delivered" || order.status == "canceled") &&
        order.claimer.isNotEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildReorderButton("Reorder with \$", false, order),
          _buildReorderButton("Reorder with pts", true, order),
        ],
      );
    } else if (order.status == "unready") {
      return Center(
        child: SpinKitThreeBounce(
          color: activeColor,
          size: 25,
        ),
      );
    } else if (order.status == "ready" && order.claimer.isNotEmpty) {
      return Center(
        child: SizedBox(
          height: 40,
          child: AnimatedTextKit(
            animatedTexts: [
              FadeAnimatedText(
                'Order #${order.userId} is ready',
                textStyle: GoogleFonts.poppins(
                  color: activeColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                duration: const Duration(milliseconds: 3000),
              ),
            ],
            isRepeatingAnimation: true,
            repeatForever: true,
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  Widget _buildReorderButton(String label, bool usePoints, CustomerOrder order) {
    return GestureDetector(
      onTap: () => _triggerReorder(order, usePoints),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerReorder(CustomerOrder order, bool usePoints) async {
    final hierarchy = Provider.of<Hierarchy>(context, listen: false);
    final reorder = {
      "action": "create",
      "barId": int.parse(order.barId),
      "userId": order.userId,
      "points": usePoints,
      "drinks": order.drinks.map((drinkOrder) {
        return {
          'drinkId': int.parse(drinkOrder.id),
          'quantity': int.parse(drinkOrder.quantity),
        };
      }).toList(),
    };

    hierarchy.createOrder(reorder);
    _pageController.jumpToPage(0);
  }
}