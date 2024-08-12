import 'package:barzzy_app1/OrdersPage/hierarchy.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: AppBar(
        title: const Text('Orders Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {}); // Refresh the UI to update order list
            },
          ),
        ],
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

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final barId = orders.keys.elementAt(index);
              final order = orders[barId];
              return ListTile(
                title: Text(
                  'Bar ID: $barId',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'User ID: ${order?['userId']}\nOrder ID: ${order?['orderId']}',
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _clearOrders(context);
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.delete),
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
