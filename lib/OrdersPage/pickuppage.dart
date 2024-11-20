import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:barzzy/MenuPage/cart.dart';
import 'package:barzzy/OrdersPage/websocket.dart';
import 'package:barzzy/Backend/activeorder.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  int currentPage = 0;

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
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey)),
          ),
          child: Text(
            'Orders',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
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
                child: orders.isEmpty
                    ? const Center(
                        child: Text(
                          'No orders have been placed yet.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                          ),
                        ),
                      )
                    : PageView.builder(
                        controller: _pageController,
                        scrollDirection: Axis.vertical,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: orders.length,
                        itemBuilder: (context, verticalIndex) {
                          final barId = orders[verticalIndex];
                          final order = localDatabase.getOrderForBar(barId);

                          if (order == null) {
                            return const Center(
                              child: Text(
                                'No orders found for this bar.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                ),
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
          const Spacer(flex: 1),
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
              const SizedBox(height: 30),
              Text(
                bar?.name ?? 'No Tag',
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
          const Spacer(flex: 1),
          _buildDrinksGrid(order.drinks),
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

    IconData inQueueIcon = Icons.access_time;
    IconData claimedIcon = Icons.wine_bar;
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
          backgroundColor:
              status == "delivered" ? Colors.blueGrey : Colors.red.shade300,
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

  Widget _buildDrinksGrid(List<DrinkOrder> drinks) {
    const drinksPerPage = 6; // Maximum drinks per page
    final totalPages =
        (drinks.length / drinksPerPage).ceil(); // Calculate total pages

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
              height: drinks.length <= 3 ? 62 : 125,
              child: PageView.builder(
                itemCount: totalPages,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index; // Update the current page
                  });
                },
                itemBuilder: (context, pageIndex) {
                  // Get the drinks for the current page
                  final startIndex = pageIndex * drinksPerPage;
                  final endIndex =
                      (startIndex + drinksPerPage).clamp(0, drinks.length);
                  final pageDrinks = drinks.sublist(startIndex, endIndex);

                  // If there's 1 or 2 drinks, center them manually
                  if (pageDrinks.length <= 2) {
                    return Center(
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: pageDrinks.map((drink) {
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
                                  drink.drinkName,
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
                                  'x${drink.quantity}${drink.sizeType.isNotEmpty ? ' (${drink.sizeType})' : ''}',
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

                  // Default grid view for more than 2 drinks
                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 3 drinks per row
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      childAspectRatio: 2.0,
                    ),
                    itemCount: pageDrinks.length,
                    itemBuilder: (context, index) {
                      final drink = pageDrinks[index];
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
                              drink.drinkName,
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
                              'x${drink.quantity}${drink.sizeType.isNotEmpty ? ' (${drink.sizeType})' : ''}',
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
          child: AnimatedTextKit(
            animatedTexts: [
              FadeAnimatedText(
                "Order #${order.userId} is now in queue",
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
    } else if (order.status == "unready" && order.claimer.isNotEmpty) {
      return Center(
        child: SizedBox(
          height: 40,
          child: AnimatedTextKit(
            animatedTexts: [
              FadeAnimatedText(
                'Order #${order.userId} is being prepared',
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
    } else if (order.status == "ready" && order.claimer.isNotEmpty) {
      return Center(
        child: SizedBox(
          height: 40,
          child: AnimatedTextKit(
            animatedTexts: [
              FadeAnimatedText(
                'Order #${order.userId} is ready at station ${order.claimer} ',
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

  Widget _buildReorderButton(CustomerOrder order) {
    return GestureDetector(
      onTap: () async {
        final barId = order.barId;
        final cart = Cart();
        cart.setBar(barId);

        // Use the reorder method to reset the cart based on the order
        cart.reorder(order);

        // Navigate to MenuPage
        await Navigator.of(context).pushNamed(
          '/menu',
          arguments: {
            'barId': barId,
            'cart': cart,
            'drinkId':
                order.drinks.first.drinkId.toString(), // Optional drinkId.
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              "       Reorder        ",
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
}
