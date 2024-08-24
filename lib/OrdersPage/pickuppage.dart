import 'package:barzzy_app1/AuthPages/RegisterPages/logincache.dart';
import 'package:barzzy_app1/OrdersPage/hierarchy.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Backend/localdatabase.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;

class PickupPage extends StatefulWidget {
  const PickupPage({super.key});

  @override
  State<PickupPage> createState() => PickupPageState();
}

class PickupPageState extends State<PickupPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 55,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                gradient: LinearGradient(
                  colors: [Colors.black, Colors.grey.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Consumer<Hierarchy>(
                builder: (context, hierarchy, child) {
                  final orders = hierarchy.getOrders();

                  if (orders.isEmpty) {
                    return const SizedBox();
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_currentPage + 1}/${orders.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(
                          Icons.receipt_long,
                          color: Colors.white,
                          size: 28,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
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
                        'No orders found.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final reversedOrderKeys = orders.reversed.toList();

                  return PageView.builder(
                    controller: _pageController,
                    itemCount: reversedOrderKeys.length,
                    scrollDirection: Axis.vertical,
                    onPageChanged: (index) async {
                      setState(() {
                        _currentPage = index;
                      });

                      final barId = reversedOrderKeys[index].toString();
                      await _writeToNfc(barId);  // Writing to NFC when the page changes
                    },
                    itemBuilder: (context, index) {
                      final barId = reversedOrderKeys[index].toString();
                      final localDatabase = LocalDatabase();

                      final bar = LocalDatabase.getBarById(barId);
                      final order = localDatabase.getOrderForBar(barId);

                      if (bar == null || order == null) {
                        return const Center(
                          child: Text(
                            'Data not found.',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      final drinkQuantities = order.drinkQuantities;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25.0),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.05),
                                      Colors.white.withOpacity(0.15),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Status: ${order.status}',
                                        style: const TextStyle(
                                          color: Colors.greenAccent,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Claimer: ${order.claimer.isNotEmpty ? order.claimer : 'None'}',
                                        style: const TextStyle(
                                          color: Colors.orangeAccent,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: drinkQuantities.entries.map((entry) {
                                      final drink = localDatabase.getDrinkById(entry.key);
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: Text(
                                          '${drink.getName() ?? 'Unknown'}: ${entry.value}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 18,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total: \$${order.getPrice()?.toStringAsFixed(2) ?? '0.00'}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
        ),
      ),
    );
  }

 Future<void> _writeToNfc(String barId) async {
  try {
    // Retrieve the userId from LoginCache
    final loginCache = Provider.of<LoginCache>(context, listen: false);
    final userId = await loginCache.getUID();

    if (userId == null) {
      throw Exception("User ID is null.");
    }

    // Poll for NFC tag
    final tag = await FlutterNfcKit.poll(
      timeout: Duration(seconds: 10),
      iosMultipleTagMessage: "Multiple tags found!",
      iosAlertMessage: "Scan your tag",
    );

    if (tag == null) {
      throw Exception("No NFC tag detected.");
    }

    // Prepare data to write
    final dataToWrite = 'barId: $barId, userId: $userId';

    // Write NDEF records
    await FlutterNfcKit.writeNDEFRecords([
      NDEFRecord.text(dataToWrite) // This will cause an error
    ]);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('NFC tag written with barId: $barId, userId: $userId')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to write to NFC tag: $e')),
    );
  } finally {
    await FlutterNfcKit.finish(
      iosAlertMessage: "Success",
    );
  }
}
}