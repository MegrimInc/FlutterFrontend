import 'package:barzzy_app1/AuthPages/RegisterPages/logincache.dart';
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
  bool _isGridView = true; // Toggle between Grid and Card view
  String? _selectedBarId; // Keep track of the selected bar ID

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
                        'No orders found.',
                        style: TextStyle(color: Colors.white),
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
            width: 0.5,
          ),
        ),
        gradient: LinearGradient(
          colors: [Colors.black, Colors.grey.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (!_isGridView && _selectedBarId != null)
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _selectedBarId = null;
                  });
                },
              ),
            Text(
              _isGridView
                  ? 'Select a Bar'
                  : 'Bar Details',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(
                _isGridView ? Icons.view_list : Icons.grid_view,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(List<String> barIds) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
      ),
      padding: const EdgeInsets.all(10.0),
      itemCount: barIds.length,
      itemBuilder: (context, index) {
        final barId = barIds[index];
        final bar = LocalDatabase.getBarById(barId);

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedBarId = barId;
              _isGridView = false;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                bar?.tagimg ?? 'https://www.barzzy.site/images/default.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardView(String barId) {
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.network(
                      bar.tagimg ?? 'https://www.barzzy.site/images/default.png',
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
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: drinkQuantities.entries.map((entry) {
                    final drink = localDatabase.getDrinkById(entry.key);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        '${drink.getName() ?? 'Unknown'} x ${entry.value}',
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
  }
}