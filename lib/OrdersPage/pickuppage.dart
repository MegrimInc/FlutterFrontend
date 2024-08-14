import 'package:barzzy_app1/OrdersPage/hierarchy.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PickupPage extends StatefulWidget {
  const PickupPage({super.key});

  @override
  State<PickupPage> createState() => PickupPageState();
}

class PickupPageState extends State<PickupPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: AppBar(
        title: const Text('Orders Page'),
         backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<Hierarchy>(
        builder: (context, hierarchy, child) {
          final orders = hierarchy.getOrders(); // Get orders from Hierarchy

          if (orders.isEmpty) {
            return const Center(
              child: Text(
                'No orders found.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final reversedOrderKeys = orders.keys.toList().reversed.toList();

          return PageView.builder(
            itemCount: reversedOrderKeys.length,
            itemBuilder: (context, index) {
              final barId = reversedOrderKeys[index];
              final order = orders[barId];

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
                          'Bar ID: $barId',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'User ID: ${order?['userId']}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Order ID: ${order?['orderId']}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
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
                        // Display drink quantities
                        ...?order?['drinkQuantities']?.entries.map((entry) {
                          return Text(
                            'Drink ID: ${entry.key} - Quantity: ${entry.value}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          );
                        }).toList(),
                        const Spacer(),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Unclaimed'),
                            ElevatedButton(
                              onPressed: () {
                                final hierarchy = Provider.of<Hierarchy>(context, listen: false);
                                hierarchy.clearExpiredOrders(); 
                                _clearOrders(context);// Call the clearExpiredOrders method
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
      
    );
  }

  void _clearOrders(BuildContext context) {
    final hierarchy = Provider.of<Hierarchy>(context, listen: false);
    hierarchy.clearOrders();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All orders cleared!')),
    );
    setState(() {}); // Refresh the UI after clearing orders
  }
}
