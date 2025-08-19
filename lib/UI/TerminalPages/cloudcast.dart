import 'package:megrim/UI/TerminalPages/inventory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

class CloudCastPage extends StatefulWidget {
  final int employeeId;
  final PageController pageController;
  final int merchantId;

  const CloudCastPage(
      {super.key,
      required this.employeeId,
      required this.merchantId,
      required this.pageController});

  @override
  State<CloudCastPage> createState() => _CloudCastPageState();
}

class _CloudCastPageState extends State<CloudCastPage> {
  @override
  void initState() {
    super.initState();
    debugPrint("CloudCastPage widget initialized.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                // Left Side: Items List (50%)

                Expanded(
                  flex: 6,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      border: Border(
                        right: BorderSide(
                            color: Colors.white, width: .25), // Right border
                      ),
                    ),
                    child: buildItemList(),
                  ),
                ),

                // Right Side: Categories List (50%)
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      border: Border(
                          //right: BorderSide(color: Colors.white, width: .25),
                          ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: buildCategoryList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                color: Colors.black,
                border: Border(
                  top: BorderSide(color: Colors.white, width: 0.25),
                  //  right: BorderSide(color: Colors.white, width: 0.25),
                  //  left: BorderSide(color: Colors.white, width: 0.25),
                ),
              ),
              padding: const EdgeInsets.all(10),
              child: buildSummaryList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItemList() {
    return Consumer<Inventory>(
      builder: (context, inv, child) {
        final selectedCategory = inv.selectedCategory; // Default to Vodka
        final items = inv.getCategoryItems(selectedCategory);

        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Two columns
            mainAxisSpacing: 10, // Spacing between rows
            crossAxisSpacing: 10, // Spacing between columns
            childAspectRatio: 2.5, // Adjust as needed for better layout
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final itemId = items[index];
            final item = inv.getItemById(itemId);
            if (item == null) {
              return const SizedBox(); // Placeholder for invalid items
            }

            return GestureDetector(
              onTap: () {
                inv.addItem(itemId);
                debugPrint("Added ${item.name}");
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildSummaryList() {
    return Consumer<Inventory>(
      builder: (context, inv, child) {
        if (inv.inventoryCart.isEmpty) {
          return const Center(
            child: SpinKitThreeBounce(
              color: Colors.white,
              size: 50.0,
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: inv.inventoryOrder.map((entry) {
              // Split the entry to extract itemId and sizeType
              final itemId = entry;

              final item = inv.getItemById(itemId);
              if (item == null) {
                return const SizedBox.shrink();
              }

              final quantity = inv.inventoryCart[itemId]!;

              return Container(
                margin: const EdgeInsets.only(right: 10),
                width: 175,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.add_circle, color: Colors.white),
                          iconSize: 45,
                          onPressed: () {
                            inv.addItem(itemId);
                          },
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "$quantity",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.white),
                          iconSize: 45,
                          onPressed: () {
                            inv.removeItem(itemId);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget buildCategoryList() {
    return Consumer<Inventory>(
      builder: (context, inv, child) {
        final categoryNames = inv.allCategoryNames;

        return ListView(
          children: categoryNames.map((categoryName) {
            return _categoryButton(
              categoryName,
              categoryName, // Use name as the tag since it's now the key
              inv.selectedCategory,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _categoryButton(String label, String tag, String? selectedCategory) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: SizedBox(
        height: 75,
        child: ElevatedButton(
          onPressed: () {
            Provider.of<Inventory>(context, listen: false)
                .setSelectedCategory(tag); // Update selected category
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                selectedCategory == tag ? Colors.white : Colors.grey[800],
            padding: const EdgeInsets.all(15.0),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selectedCategory == tag ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    debugPrint("CloudCastPage widget disposed.");
    super.dispose();
  }
}