import 'package:barzzy/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy/Backend/activeorder.dart';
import 'package:barzzy/OrdersPage/hierarchy.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for haptic feedback
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import for shared preferences
import '../Backend/localdatabase.dart';

class PickupPage extends StatefulWidget {
  const PickupPage({super.key});

  @override
  State<PickupPage> createState() => PickupPageState();
}

class PickupPageState extends State<PickupPage> {
  bool _isGridView = true; // Toggle between Grid and Card view
  String? _selectedBarId; // Keep track of the selected bar ID

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Load the selected bar ID from shared preferences
    _loadAndSetSelectedBar();
  }

  Future<void> _loadAndSetSelectedBar() async {
    // Load the bar ID from shared preferences
    final prefs = await SharedPreferences.getInstance();
    final savedBarId = prefs.getString('selected_bar_id');

    // Get the barId from the arguments
    // ignore: use_build_context_synchronously
    final barId = ModalRoute.of(context)?.settings.arguments as String?;

    // If a new barId is passed in arguments, use it; otherwise, fall back to saved barId
    if (barId != null && barId != _selectedBarId) {
      // Argument barId should take precedence
      setState(() {
        _selectedBarId = barId;
        _isGridView = false;
      });

      // Save this new barId to shared preferences
      await _saveSelectedBar(barId);
    } else if (savedBarId != null && _selectedBarId == null) {
      // No new barId, so use the saved one
      setState(() {
        _selectedBarId = savedBarId;
        _isGridView = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Consumer<Hierarchy>(
                builder: (context, hierarchy, child) {
                  if (!hierarchy.isConnected) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    );
                  }

                  final orders = hierarchy.getOrders();

                  if (orders.isEmpty) {
                    return const Center(
                      child: Text(
                        'No orders have been placed yet.',
                        style: TextStyle(color: Colors.white, fontSize: 17),
                      ),
                    );
                  }

                  if (_isGridView) {
                    return _buildGridView(orders);
                  } else if (_selectedBarId != null) {
                    return _buildCardView(_selectedBarId!);
                  } else {
                    return const Center(
                      child: Text(
                        'Select a bar to view details.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _isGridView ? 'Tabs' : 'Order Details',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!_isGridView)
              GestureDetector(
                onTap: () {
                  _clearSelectedBar(); // Clear selected bar when switching back to grid view
                  setState(() {
                    _isGridView = true;
                  });
                },
                child: Container(
                  color: Colors.transparent,
                  height: 50, // Increase the height of the pressable area
                  width: 50, // Increase the width of the pressable area
                  alignment: Alignment
                      .centerRight, // Center the icon within the container
                  child: const Icon(Icons.grid_view,
                      color: Colors.white, size: 30),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(List<String> barIds) {
    return LiquidPullToRefresh(
      onRefresh: () => _refreshCardView(context),
      showChildOpacityTransition: false,
      color: Colors.black,
      height: 100,
      animSpeedFactor: 5,
      springAnimationDurationInMilliseconds: 1000,
      child: SingleChildScrollView(
        child: SizedBox(
          height: 667,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 5.0,
              mainAxisSpacing: 10.0,
              childAspectRatio: .1,
            ),
            padding: const EdgeInsets.only(top: 30),
            itemCount: barIds.length,
            itemBuilder: (context, index) {
              final barId = barIds[index];
              final bar = LocalDatabase.getBarById(barId);

              return GestureDetector(
                onTap: () {
                  debugPrint('Grid item tapped. Bar ID: $barId');
                  _saveSelectedBar(barId); // Save the selected bar ID
                  setState(() {
                    _selectedBarId = barId;
                    _isGridView = false; // Switch to card view
                  });
                },
                child: Column(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: bar?.tagimg ??
                              'https://www.barzzy.site/images/default.png',
                          fit: BoxFit.cover,
                          width: 105, // Adjust as needed
                          height: 105, // Adjust as needed
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: Text(
                        bar?.tag ?? 'No Tag',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis, // Handle long text
                        maxLines: 1, // Ensure text doesn't overflow
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCardView(String barId) {
    final bar = LocalDatabase.getBarById(barId);
    final localDatabase = LocalDatabase();
    final order = localDatabase.getOrderForBar(barId);

    if (bar == null || order == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    final status = order.status;
    final claimer = order.claimer;
    final userId = order.userId;

    return GestureDetector(
      onLongPress: () {
        final hierarchy = Provider.of<Hierarchy>(context, listen: false);
        if (status == "delivered" || status == "canceled") {
          _triggerReorder(order,
              context); // Trigger reorder for delivered or canceled orders
          HapticFeedback.heavyImpact();
        } else if (status == "unready" && claimer.isEmpty) {
          //hierarchy.cancelOrder(int.parse(barId), userId);
          hierarchy.cancelOrder(order);
          HapticFeedback.heavyImpact();
        }
      },
      child: LiquidPullToRefresh(
        onRefresh: () => _refreshCardView(context),
        showChildOpacityTransition: false,
        color: Colors.black,
        height: 100,
        animSpeedFactor: 5,
        springAnimationDurationInMilliseconds: 1000,
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: CachedNetworkImage(
                            imageUrl: bar.tagimg ??
                                'https://www.barzzy.site/images/default.png',
                            width: 105,
                            height: 105,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          bar.getName() ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                      SizedBox(
                        height: 409,
                        child: ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: order.drinks.length,
                          itemBuilder: (context, index) {
                            final drinkOrder = order.drinks[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Center(
                                child: Text(
                                  '${drinkOrder.drinkName} x ${drinkOrder.quantity}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                if (status != "delivered" &&
                    status != "canceled" &&
                    claimer != "" &&
                    status != "unready")
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Text(
                      '#${order.getUser() ?? '...'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                Positioned(
                  bottom: 1.5,
                  right: 0,
                  child: _buildStatusButton(
                      status, claimer, int.parse(barId), userId, context),
                ),

                if (status == "unready" && claimer.isNotEmpty)
                  Positioned(
                    bottom: 15,
                    right: 0,
                    left: 15,
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 25),
                          child: Center(
                            child: SpinKitThreeBounce(
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            '#${order.getUser() ?? '...'} IS BEING PREPARED @$claimer',
                            style: const TextStyle(
                                color: Color.fromARGB(255, 255, 241, 118),
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ),

                if (status == "ready" && claimer.isNotEmpty)
                  const Positioned(
                    bottom: 50,
                    right: 0,
                    left: 15,
                    child: Center(
                        child: Text(
                      'READY',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    )),
                  ),

                // Add "HOLD TO CANCEL" text at the bottom
                if (status == "unready" && claimer.isEmpty)
                  const Positioned(
                    bottom: 15,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: 25),
                          child: Center(
                            child: SpinKitThreeBounce(
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            'HOLD TO CANCEL ORDER',
                            style: TextStyle(
                                color: Color.fromARGB(255, 255, 137, 129),
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Add "HOLD TO REORDER" text for delivered or canceled orders
                if (status == "delivered" || status == "canceled")
                  const Positioned(
                    bottom: 15,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'HOLD TO REORDER',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Method to trigger reorder by creating an order
  void _triggerReorder(CustomerOrder order, BuildContext context) async {
    final hierarchy = Provider.of<Hierarchy>(context, listen: false);
    final loginCache = Provider.of<LoginCache>(context, listen: false);
    final userId = await loginCache.getUID();

    // Construct the order object for the reorder
    final reorder = {
      "action": "create",
      "barId": int.parse(order.barId), // Assuming barId is a String, convert to int if needed
      "userId": userId,
      "points": order.points,
      "drinks": order.drinks.map((drinkOrder) {
        return {
          'drinkId':
              int.parse(drinkOrder.id), // Convert drinkId to int if necessary
          'quantity': int.parse(
              drinkOrder.quantity), // Convert quantity to int if necessary
        };
      }).toList(),
    };

    // Pass the order object to the createOrder method
    hierarchy.createOrder(reorder);
  }

  // Method to build the dynamic button based on status and claimer
  Widget _buildStatusButton(String status, String claimer, int barId,
      int userId, BuildContext context) {
    // Case: Status is "unready" and claimer is not empty
    // if (status == "unready" && claimer.isNotEmpty) {
    //   return Text(
    //     '@$claimer',
    //     style: const TextStyle(
    //       color: Colors.white,
    //       fontWeight: FontWeight.bold,
    //       fontSize: 34.5,
    //     ),
    //   );
    // }

    // Case: Status is "ready" and claimer is not empty
    if (status == "ready" && claimer.isNotEmpty) {
      return Text(
        '@$claimer',
        style: const TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
          fontSize: 34.5,
        ),
      );
    }

    // Case: Status is "delivered" or "canceled"
    if (status == "delivered" || status == "canceled") {
      return Container(); // No button needed in this state, only "HOLD TO ORDER AGAIN" text is shown.
    }

    // Default case if none of the conditions match
    return Container();
  }
}

// Method to save the selected bar from shared preferences

Future<void> _saveSelectedBar(String barId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('selected_bar_id', barId);
}

// Method to clear the selected bar from shared preferences
Future<void> _clearSelectedBar() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('selected_bar_id');
}

Future<void> _refreshCardView(BuildContext context) async {
  final hierarchy = Provider.of<Hierarchy>(context, listen: false);
  hierarchy.sendRefreshMessage(context);
  debugPrint('Card view has been refreshed.');
}
