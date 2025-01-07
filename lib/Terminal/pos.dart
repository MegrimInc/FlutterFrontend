import 'dart:async';
import 'dart:convert';
import 'package:barzzy/Terminal/inventory.dart';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class POSPage extends StatefulWidget {
  final String bartenderId;
  final PageController pageController;

  const POSPage({
    super.key, 
    required this.bartenderId,
    required this.pageController
    });

  @override
  State<POSPage> createState() => _POSPageState();
}

class _POSPageState extends State<POSPage> with WidgetsBindingObserver {
  final PeripheralManager _peripheralManager = PeripheralManager();
  late String serviceUuid;
  static const String readCharacteristicUuid =
      "d973f26e-8da7-4a96-a7d6-cbca9f2d9a7e";
  late GATTService gattService;
  String selectedCategory = 'tag172';
  StreamSubscription? _characteristicReadSubscription;

  @override
  void initState() {
    super.initState();
    debugPrint("POSPage widget initialized.");
    WidgetsBinding.instance.addObserver(this);
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

    await clearBLE();

    serviceUuid = const Uuid().v4();
    debugPrint("Generated new service UUID: $serviceUuid");

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
      debugPrint("GATT services added successfully");
    } catch (error) {
      debugPrint("Error adding GATT services: $error");
    }

    // Listen for read requests and store the subscription
    _characteristicReadSubscription =
        _peripheralManager.characteristicReadRequested.listen(_onReadRequest);

    debugPrint("Peripheral initialization completed");

    _startAdvertising();
  }

  
  Future<void> _onReadRequest(
      GATTCharacteristicReadRequestedEventArgs args) async {
    debugPrint("Read request received.");

    // Check if the widget is mounted before accessing context
    if (!mounted) {
      debugPrint("Widget is unmounted. Skipping read request processing.");
      return;
    }

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

        widget.pageController.animateToPage(
      1, // The target page index
      duration: const Duration(milliseconds: 300), // Animation duration
      curve: Curves.easeInOut, // Animation curve
    );

      debugPrint("Read request responded with inventory data.");
    } catch (error, stackTrace) {
      debugPrint("Error responding to read request: $error");
      debugPrint("Stack trace: $stackTrace");
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

      debugPrint("BLE advertising started.");
    } catch (e) {
      debugPrint("Error starting BLE advertising: $e");
    }
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
                // Left Side: Drinks List (50%)

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
                    child: buildDrinkList(),
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

  Widget buildDrinkList() {
    return Consumer<Inventory>(
      builder: (context, inv, child) {
        final selectedCategory = inv.selectedCategory; // Default to Vodka
        final drinks = inv.getCategoryDrinks(selectedCategory);

        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Two columns
            mainAxisSpacing: 10, // Spacing between rows
            crossAxisSpacing: 10, // Spacing between columns
            childAspectRatio: 2.5, // Adjust as needed for better layout
          ),
          itemCount: drinks.length,
          itemBuilder: (context, index) {
            final drinkId = drinks[index];
            final drink = inv.getDrinkById(drinkId.toString());
            if (drink == null) {
              return const SizedBox(); // Placeholder for invalid drinks
            }

            return GestureDetector(
              onTap: () {
                // Add drink as single if single and double prices are the same
                if (drink.singlePrice == drink.doublePrice) {
                  inv.addDrink(drinkId.toString(), isDouble: false);
                  debugPrint("Added ${drink.name} as single (same price).");
                } else {
                  inv.addDrink(drinkId.toString(), isDouble: false);
                  debugPrint(
                      "Added ${drink.name} as single (different price).");
                }
              },
             onDoubleTap: drink.singlePrice != drink.doublePrice
                ? () {
                    inv.addDrink(drinkId.toString(), isDouble: true);
                    debugPrint("Added ${drink.name} as double.");
                  }
                : null,
              child: Container(
                decoration: BoxDecoration(
                  color: drink.singlePrice == drink.doublePrice
                      ? Colors.grey[900]
                      : Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: Text(
                    drink.name,
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
            // Split the entry to extract drinkId and sizeType
            final parts = entry.split('-');
            final drinkId = parts[0];
            final sizeType = parts[1];

            final drink = inv.getDrinkById(drinkId);
            if (drink == null) {
              return const SizedBox.shrink();
            }

            final sizeLabel = (sizeType == "double" || sizeType == "single") &&
                    drink.singlePrice != drink.doublePrice
                ? (sizeType == "double" ? " (dbl)" : " (sgl)")
                : "";

            final quantity = inv.inventoryCart[drinkId]![sizeType] ?? 0;

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
                    "${drink.name}$sizeLabel",
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
                        icon: const Icon(Icons.add_circle, color: Colors.white),
                        iconSize: 45,
                        onPressed: () {
                          inv.addDrink(drinkId, isDouble: sizeType == "double");
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
                        icon: const Icon(Icons.remove_circle, color: Colors.white),
                         iconSize: 45,
                        onPressed: () {
                          inv.removeDrink(drinkId, isDouble: sizeType == "double");
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
    final categories = {
      'Lager': 'tag179',
      'Vodka': 'tag172',
      'Tequila': 'tag175',
      'Whiskey': 'tag174',
      'Gin': 'tag173',
      'Brandy': 'tag176',
      'Rum': 'tag177',
      'Seltzer': 'tag186',
      'Special': 'special',
      'Ale': 'tag178',
      'Red Wine': 'tag183',
      'White Wine': 'tag184',
      'Virgin': 'tag181',
    };

    return Consumer<Inventory>(
      builder: (context, inv, child) {
        final filteredCategories = categories.entries
            .where((entry) => inv.getCategoryDrinks(entry.value).isNotEmpty)
            .toList();

        return ListView(
          children: filteredCategories.map((entry) {
            return _categoryButton(
                entry.key, entry.value, inv.selectedCategory);
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

  Future<void> clearBLE() async {
    debugPrint("Clearing BLE resources...");
    try {
      // Stop advertising
      await _peripheralManager.stopAdvertising();
      debugPrint("BLE advertising stopped successfully.");

      // Remove all services
      await _peripheralManager.removeAllServices();
      debugPrint("All BLE services removed successfully.");

      // Cancel characteristic read subscription
      if (_characteristicReadSubscription != null) {
        await _characteristicReadSubscription?.cancel();
        _characteristicReadSubscription = null;
        debugPrint("Characteristic read subscription canceled successfully.");
      }

    } catch (error, stackTrace) {
      debugPrint("Error clearing BLE resources: $error");
      debugPrint("Stack trace: $stackTrace");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.paused) {
      clearBLE();
    } else if (state == AppLifecycleState.resumed) {
      _requestPermissions();
    }
  }

  @override
  void dispose() {
    debugPrint("POSPage widget disposed.");
    WidgetsBinding.instance.removeObserver(this);
    clearBLE();
    super.dispose();
  }
}
