import 'dart:convert';
import 'dart:typed_data';
import 'package:barzzy/Terminal/inventory.dart';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class POSPage extends StatefulWidget {
  final String bartenderId;

  const POSPage({super.key, required this.bartenderId});

  @override
  State<POSPage> createState() => _POSPageState();
}

class _POSPageState extends State<POSPage> {
  final PeripheralManager _peripheralManager = PeripheralManager();
  //static const String serviceUuid = "25f7d535-ab21-4ae5-8d0b-adfae5609005";
  final String serviceUuid = const Uuid().v4();
  static const String readCharacteristicUuid =
      "d973f26e-8da7-4a96-a7d6-cbca9f2d9a7e";
  final ValueNotifier<String> statusNotifier =
      ValueNotifier("Waiting for connection...");
  late GATTService gattService;
  bool isBroadcasting = false;
  bool isDeviceConnected = false;
  String selectedCategory = 'tag172';

  @override
  void initState() {
    super.initState();
    debugPrint("POSPage widget initialized.");
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    debugPrint("Requesting permissions...");
    if (await Permission.bluetooth.isDenied) {
      debugPrint("Bluetooth permission denied. Requesting...");
      await Permission.bluetooth.request();
    } else {
      debugPrint("Bluetooth permission already granted.");
    }

    if (await Permission.location.isDenied) {
      debugPrint("Location permission denied. Requesting...");
      await Permission.location.request();
    } else {
      debugPrint("Location permission already granted.");
    }
    _initializePeripheral();
  }

  Future<void> _initializePeripheral() async {
    debugPrint("Initializing peripheral...");

    _peripheralManager.stopAdvertising();
    _peripheralManager.removeAllServices();

    // Convert predefined characteristic UUIDs to byte arrays
    final serviceUuidBytes = _stringToBytes(serviceUuid);
    final readCharacteristicBytes = _stringToBytes(readCharacteristicUuid);

    // Main Service
    final gattService = GATTService(
      uuid: UUID(serviceUuidBytes), // Custom Service UUID
      characteristics: [
        GATTCharacteristic.mutable(
          uuid: UUID(readCharacteristicBytes), // Read
          properties: [GATTCharacteristicProperty.read],
          permissions: [GATTCharacteristicPermission.read],
          descriptors: [],
        ),
      ],
      isPrimary: true,
      includedServices: [],
    );

    debugPrint("GATT service created with UUID: ${gattService.uuid}");

    try {
      await _peripheralManager.addService(gattService);
      debugPrint("GATT service added successfully");
    } catch (error) {
      debugPrint("Error adding GATT services: $error");
    }

    _peripheralManager.characteristicReadRequested.listen(_onReadRequest);

    debugPrint("Peripheral initialization completed");
  }

  Future<void> _onReadRequest(
      GATTCharacteristicReadRequestedEventArgs args) async {
    debugPrint("Read request received.");

    try {
      final inv = Provider.of<Inventory>(context, listen: false);
      // Serialize the current inventory cart
      final serializedInventory =
          inv.serializeInventoryCart(inv.inventoryCart, widget.bartenderId);

      debugPrint("Serialized inventory cart: $serializedInventory");

      // Convert the serialized inventory to a byte array
      final responseValue =
          Uint8List.fromList(utf8.encode(serializedInventory));

      // Respond to the read request with the serialized data
      await _peripheralManager.respondReadRequestWithValue(
        args.request,
        value: responseValue,
      );

      debugPrint("Read request responded with inventory data.");
    } catch (error, stackTrace) {
      debugPrint("Error responding to read request: $error");
      debugPrint("Stack trace: $stackTrace");
    }
  }

  Future<void> _toggleAdvertising() async {
    debugPrint("Toggle advertising button pressed.");
    if (isBroadcasting) {
      debugPrint("Stopping advertising...");
      await _stopAdvertising();
    } else {
      debugPrint("Starting advertising...");
      await _startAdvertising();
    }
  }

  Future<void> _startAdvertising() async {
    debugPrint("Attempting to start BLE advertising...");

    final inv = Provider.of<Inventory>(context, listen: false);
    final barId = inv.bar.id ?? "UnknownTag";
    final bartenderId = widget.bartenderId;

    final advertisement = Advertisement(
      name: "$barId~$bartenderId|${const Uuid().v4()}",
      serviceUUIDs: [
        UUID(_stringToBytes(serviceUuid)) // Add service UUID if needed
      ],
    );

    try {
      await _peripheralManager.startAdvertising(advertisement);
      setState(() {
        isBroadcasting = true;
      });
      debugPrint("BLE advertising started.");
    } catch (e) {
      debugPrint("Error starting BLE advertising: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = Provider.of<Inventory>(context, listen: false);
    final drinksInCategory = inv.getCategoryDrinks(selectedCategory);

    return Scaffold(
      body: Column(
        children: [
          // Main Row with Drinks List and Categories
          Expanded(
            child: Row(
              children: [
                // Left Side: Drinks List (70%)
                Expanded(
                  flex: 7,
                  child: Container(
                    color: Colors.black,
                    child: ListView.builder(
                      itemCount: drinksInCategory.length,
                      itemBuilder: (context, index) {
                        final drinkId = drinksInCategory[index];
                        final drink = inv.getDrinkById(drinkId.toString());

                        if (drink == null) {
                          return const ListTile(
                            title: Text(
                              'Unknown Drink',
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }

                        return Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 10),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              // Drink Name
                              Expanded(
                                flex: 3,
                                child: Text(
                                  drink.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              // Add Buttons
                              if (drink.singlePrice == drink.doublePrice)
                                // If single and double prices are the same, show one button
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      inv.addDrink(drinkId.toString(),
                                          isDouble: false);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    child: const Text(
                                      "Add 1",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                )
                              else
                                // If single and double prices are different, show two buttons
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      // Add Single Button
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            inv.addDrink(drinkId.toString(),
                                                isDouble: false);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                          ),
                                          child: const Text(
                                            "Add Single",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      // Add Double Button
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            inv.addDrink(drinkId.toString(),
                                                isDouble: true);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                          ),
                                          child: const Text(
                                            "Add Double",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Right Side: Categories List (30%)
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      border: Border(
                        left: BorderSide(
                            color: Colors.white, width: .25), // Top border
                        bottom: BorderSide(
                            color: Colors.white, width: .25), // Right border
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: buildCategoryList(),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Row
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.15,
            child: Row(
              children: [
                // Left Section of Bottom Row (70%)
                Expanded(
                  flex: 7,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      border: Border(
                        top: BorderSide(
                            color: Colors.white, width: 0.25), // Top border
                        right: BorderSide(
                            color: Colors.white, width: 0.25), // Right border
                      ),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Consumer<Inventory>(
                      builder: (context, inv, child) {
                        if (inv.inventoryCart.isEmpty) {
                          // Display this when the inventoryCart is empty
                          return const Center(
                            child: Text(
                              'Empty',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }

                        // Process the inventoryCart when it's not empty
                        return ListView(
                          children: inv.inventoryCart.keys.map((drinkId) {
                            final drink = inv.getDrinkById(drinkId);
                            if (drink == null) {
                              return const SizedBox
                                  .shrink(); // Skip invalid drinks
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: inv.inventoryCart[drinkId]!.entries
                                  .map((entry) {
                                // Extract size information
                                final sizeText = entry.key.contains("double")
                                    ? " (dbl)"
                                    : entry.key.contains("single")
                                        ? " (sgl)"
                                        : "";

                                // Construct display name with size and quantity
                                final displayText =
                                    "${entry.value} ${drink.name}$sizeText";

                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.add,
                                          color: Colors.green),
                                      onPressed: () {
                                        inv.addDrink(drinkId,
                                            isDouble:
                                                entry.key.contains("double"));
                                      },
                                    ),

                                    // Drink Name
                                    Text(
                                      displayText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),

                                    IconButton(
                                      icon: const Icon(Icons.remove,
                                          color: Colors.red),
                                      onPressed: () {
                                        inv.removeDrink(drinkId,
                                            isDouble:
                                                entry.key.contains("double"));
                                      },
                                    ),
                                  ],
                                );
                              }).toList(),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ),

                // Right Section of Bottom Row (30%)
                Expanded(
                  flex: 3,
                  child: Container(
                    color: Colors.black,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: ElevatedButton(
                            onPressed: _toggleAdvertising,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isBroadcasting ? Colors.red : Colors.green,
                            ),
                            child: Text(
                              isBroadcasting
                                  ? "Stop Advertising"
                                  : "Start Advertising",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Build the vertical list of categories
  Widget buildCategoryList() {
    // Define a map of category names to their tags
    final categories = {
      'Lager': 'tag179',
      'Vodka': 'tag172',
      'Tequila': 'tag175',
      'Whiskey': 'tag174',
      'Gin': 'tag173',
      'Brandy': 'tag176',
      'Rum': 'tag177',
      'Seltzer': 'tag186',
      'Ale': 'tag178',
      'Red Wine': 'tag183',
      'White Wine': 'tag184',
      'Virgin': 'tag181',
    };

    final inv = Provider.of<Inventory>(context, listen: false);

    // Filter out categories with zero drinks
    final filteredCategories = categories.entries
        .where((entry) => inv.getCategoryDrinks(entry.value).isNotEmpty)
        .toList();

    return ListView(
      children: filteredCategories.map((entry) {
        return _categoryButton(entry.key, entry.value);
      }).toList(),
    );
  }

// Category button widget
  Widget _categoryButton(String label, String tag) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: SizedBox(
        height: 75,
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              selectedCategory = tag;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                selectedCategory == tag ? Colors.blue : Colors.grey[800],
            padding: const EdgeInsets.all(15.0),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Future<void> _stopAdvertising() async {
    debugPrint("Attempting to stop BLE advertising...");
    try {
      await _peripheralManager.stopAdvertising();
      setState(() {
        isBroadcasting = false;
      });

      debugPrint("BLE advertising stopped.");
    } catch (e) {
      debugPrint("Error stopping BLE advertising: $e");
    }
  }

  Uint8List _stringToBytes(String uuidString) {
    debugPrint("Converting UUID string to bytes: $uuidString");
    final cleanUuid = uuidString.replaceAll('-', '');

    final byteBuffer = List<int>.generate(cleanUuid.length ~/ 2, (i) {
      final byte = int.parse(cleanUuid.substring(i * 2, i * 2 + 2), radix: 16);
      return byte;
    });

    final byteList = Uint8List.fromList(byteBuffer);
    debugPrint("Final byte list: $byteList");
    return byteList;
  }

  @override
  void dispose() {
    debugPrint("POSPage widget disposed.");
    _peripheralManager.removeAllServices();
    _peripheralManager.stopAdvertising();
    super.dispose();
  }
}
