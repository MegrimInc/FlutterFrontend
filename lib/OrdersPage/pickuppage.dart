import 'package:barzzy_app1/OrdersPage/hierarchy.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Backend/localdatabase.dart';

class PickupPage extends StatefulWidget {
  const PickupPage({super.key});

  @override
  State<PickupPage> createState() => PickupPageState();
}

class PickupPageState extends State<PickupPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 55,
              decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color.fromARGB(255, 126, 126, 126),
                            width: 0.1,
                          ),
                        ),
                      ),
              child: Row(
                children: [
            
              ],
              )
            ),
            Expanded(
              child: Consumer<Hierarchy>(
                builder: (context, hierarchy, child) {
                  // Check if the connection is not established
                  if (!hierarchy.isConnected) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    );
                  }
              
                  final orders = hierarchy.getOrders(); // Get orders from Hierarchy
              
                  // If there are no orders but the connection is established, show a "No orders found" message
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
                    itemCount: reversedOrderKeys.length,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (context, index) {
                      final barId = reversedOrderKeys[index].toString();
                      final localDatabase = LocalDatabase();
              
                      // Fetch the bar, order, and drink data
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
                        padding: const EdgeInsets.all(16.0),
                        child: Card(
                          color: Colors.grey[900],
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bar: ${bar.getName() ?? 'Unknown'}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Drink Quantities:',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Display drink quantities and names
                                ...drinkQuantities.entries.map((entry) {
                                  final drink = localDatabase.getDrinkById(entry.key);
                                  return Text(
                                    'Drink: ${drink?.getName() ?? 'Unknown'} - Quantity: ${entry.value}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  );
                                }).toList(),
                                const SizedBox(height: 16),
                                Text(
                                  'Total Price: \$${order.getPrice()?.toStringAsFixed(2) ?? '0.00'}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Unclaimed',
                                        style: TextStyle(color: Colors.white)),
                                    ElevatedButton(
                                      onPressed: () {
                                        // Implement cancel functionality here
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
}
