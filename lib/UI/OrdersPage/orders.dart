import 'package:megrim/Backend/database.dart';
import 'package:megrim/Backend/websocket.dart';
import 'package:megrim/DTO/customerorder.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:megrim/DTO/transaction.dart';
import 'package:megrim/UI/AuthPages/RegisterPages/logincache.dart';
import 'package:megrim/UI/Navigation/cloud.dart';
import 'package:provider/provider.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => OrdersPageState();
}

class OrdersPageState extends State<OrdersPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (mounted) {
      final websocket = Provider.of<Websocket>(context, listen: false);
      websocket.sendRefreshMessage(context);
      _fetchTransactionHistory();
    }
  }

  Future<void> _fetchTransactionHistory() async {
    final localDatabase = Provider.of<LocalDatabase>(context, listen: false);
    if (localDatabase.transactionHistory.isEmpty) {
      final loginCache = Provider.of<LoginCache>(context, listen: false);
      final customerId = await loginCache.getUID();
      await localDatabase.fetchTransactionHistory(customerId);
    } else {
      debugPrint('Transaction history already loaded, skipping fetch.');
    }
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
            final displayText = totalOrders;

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
                  "$displayText", // Display the appropriate text
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
      body: RefreshIndicator(
        onRefresh: () => _refreshOrders(context),
        color: Colors.black,
        child: Consumer2<Websocket, LocalDatabase>(
          builder: (context, websocket, localDatabase, child) {
            final activeOrderPairs = websocket.getOrders();

            final activeOrders = activeOrderPairs
                .map((pair) => localDatabase.getOrderForMerchantAndEmployee(
                    pair.key, pair.value))
                .where((order) => order != null)
                .toList();

            final transactionHistory = localDatabase.transactionHistory;
            final isHistoryLoading = localDatabase.isTransactionHistoryLoading;

            if (!websocket.isConnected || isHistoryLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (activeOrders.isNotEmpty) ...[
                  ...activeOrders.map((order) => _buildActiveOrder(order!)),
                ],
                if (transactionHistory.isNotEmpty) ...[
                  ...transactionHistory.map((order) => _buildPastOrder(order)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _refreshOrders(BuildContext context) async {
    final websocket = Provider.of<Websocket>(context, listen: false);
    websocket.sendRefreshMessage(context);
    _fetchTransactionHistory();
    debugPrint('Order list has been refreshed.');
  }

  Widget _buildActiveOrder(CustomerOrder order) {
    final merchant = LocalDatabase.getMerchantById(order.merchantId);
    final employee = Provider.of<LocalDatabase>(context, listen: false)
        .findEmployeeById(order.merchantId, order.employeeId);

    final String imageUrl = (employee?.imageUrl?.isNotEmpty ?? false)
        ? employee!.imageUrl!
        : 'https://www.barzzy.site/images/default.png';

    final String workerName = employee?.name ?? 'Loading...';
    final String customerName = order.name;

    // Merge items by name
    final Map<String, int> mergedItems = {};
    for (var item in order.items) {
      mergedItems.update(
        item.itemName,
        (existingQty) => existingQty + item.quantity,
        ifAbsent: () => item.quantity,
      );
    }

    final List<MapEntry<String, int>> itemList = mergedItems.entries.toList();

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
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${merchant?.nickname ?? "Unknown"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        workerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusIndicator(order.status),
              ],
            ),
            const SizedBox(height: 12),
            ...itemList.sublist(0, itemList.length - 1).map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${entry.key} x${entry.value}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                )),
            if (itemList.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(
                      '${itemList.last.key} x${itemList.last.value}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      customerName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                        //fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    String displayText;
    Color displayColor;

    if (status == "unready") {
      displayText = "IN QUEUE";
      displayColor = Colors.orange;
    } else if (status == "ready") {
      displayText = "READY";
      displayColor = Colors.lightGreenAccent;
    } else if (status == "arrived") {
      displayText = "ARRIVED";
      displayColor = Colors.blueAccent;
    } else if (status == "delivered") {
      displayText = "COMPLETED";
      displayColor = Colors.grey;
    } else if (status == "canceled") {
      displayText = "CANCELED";
      displayColor = Colors.red.shade300;
    } else {
      displayText = status.toUpperCase();
      displayColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: .02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: displayColor),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: displayColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPastOrder(Transaction order) {
    final merchant = LocalDatabase.getMerchantById(order.merchantId);

    // Merge items with the same name regardless of payment type
    final Map<String, int> mergedItems = {};
    for (var item in order.items) {
      mergedItems.update(
        item.itemName,
        (existingQty) => existingQty + item.quantity,
        ifAbsent: () => item.quantity,
      );
    }

    // Format timestamp inline
    String formattedTimestamp;
    try {
      final utcDateTime = DateTime.parse(order.timestamp);
      final localDateTime = utcDateTime.toLocal();

      // 12-hour time with AM/PM
      final hour = localDateTime.hour % 12 == 0 ? 12 : localDateTime.hour % 12;
      final minute = localDateTime.minute.toString().padLeft(2, '0');
      final period = localDateTime.hour >= 12 ? 'PM' : 'AM';

      formattedTimestamp =
          '${localDateTime.month}/${localDateTime.day}/${localDateTime.year} $hour:$minute $period';
    } catch (_) {
      formattedTimestamp = order.timestamp;
    }

    return GestureDetector(
      onTap: () async {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.grey,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (BuildContext context) {
            return CloudPage(transaction: order);
          },
        );
        await Provider.of<LocalDatabase>(context, listen: false)
            .fetchCategoriesAndItems(order.merchantId);
      },
      child: Container(
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
                          '\$${(order.totalRegularPrice + order.totalTax + order.totalGratuity + order.totalServiceFee).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (order.totalRegularPrice > 0 &&
                          order.totalPointPrice > 0)
                        const Text(
                          ', ',
                          style: TextStyle(
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
    super.dispose();
  }
}
