import 'dart:async';
import 'dart:convert';
import 'dart:io'; // For platform checks
import 'package:megrim/Backend/database.dart';
import 'package:megrim/DTO/merchant.dart';
import 'package:megrim/DTO/customerorder.dart';

import 'package:megrim/Backend/cart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class BlueToothScanner extends StatefulWidget {
  const BlueToothScanner({super.key});

  @override
  State<BlueToothScanner> createState() => _BlueTooth();
}

class _BlueTooth extends State<BlueToothScanner> with WidgetsBindingObserver {
  final ValueNotifier<String> bluetoothStatus =
      ValueNotifier("Checking Bluetooth permissions...");
  final ValueNotifier<bool> isScanning = ValueNotifier(false);
  final ValueNotifier<List<ScanResult>> scanResults = ValueNotifier([]);
  StreamSubscription? scanSubscription;
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    requestBluetoothPermissions();
  }

  Future<void> requestBluetoothPermissions() async {
    try {
      if (!await FlutterBluePlus.isSupported) {
        bluetoothStatus.value = "Bluetooth not supported on this device";
        return;
      }

      if (Platform.isIOS) {
        final adapterState = await FlutterBluePlus.adapterState.first;

        if (adapterState == BluetoothAdapterState.on) {
          bluetoothStatus.value = "Bluetooth permissions granted";
          startScanning();
        } else if (adapterState == BluetoothAdapterState.unauthorized) {
          bluetoothStatus.value = "Bluetooth permissions denied";
        } else if (adapterState == BluetoothAdapterState.off) {
          bluetoothStatus.value = "Bluetooth is off";
        } else {
          bluetoothStatus.value = "Unknown Bluetooth state";
          debugPrint("Retrying Bluetooth permissions request...");
          requestBluetoothPermissions(); // Automatically retry
        }
      }
    } catch (e) {
      bluetoothStatus.value = "Error requesting permissions: $e";
    }
  }

  Future<void> startScanning() async {
    if (isScanning.value) return;

    // Ensure Bluetooth is ON before starting the scan
    await FlutterBluePlus.adapterState
        .where((state) => state == BluetoothAdapterState.on)
        .first;

    isScanning.value = true;

    final Map<String, ScanResult> currentResults = {}; // Key by device remoteId
    final Map<String, DateTime> lastSeen = {};

    // Listen to scan results
    scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      final now = DateTime.now();

      for (final result in results) {
        final String advName = result.advertisementData.advName;
        final RegExp namePattern = RegExp(r'^\d+~[A-Z]\|');

        // Only include devices advertising with "Peripheral" in their name
        if (advName.isNotEmpty && namePattern.hasMatch(advName)) {
          final deviceId = result.device.remoteId.toString();
          currentResults[deviceId] = result;
          lastSeen[deviceId] = now;
        }
      }

      // **🔥 Remove Outdated Devices (Not Seen in Last 10s)**
      final List<String> toRemove = [];
      lastSeen.forEach((deviceId, timestamp) {
        if (now.difference(timestamp) > const Duration(seconds: 3)) {
          toRemove.add(deviceId);
        }
      });

      for (final deviceId in toRemove) {
        currentResults.remove(deviceId);
        lastSeen.remove(deviceId);
      }

      // Update the scanResults ValueNotifier with the sorted list
      scanResults.value = currentResults.values.toList()
        ..sort((a, b) => b.rssi.compareTo(a.rssi)); // Sort by signal strength
    });

    // Start scanning without a timeout
    FlutterBluePlus.startScan().catchError((error) {
      debugPrint("Error starting scan: $error");
      isScanning.value = false; // Reset scanning state in case of an error
    });

    debugPrint(
        "Scanning started indefinitely with live result updates and no filtering.");
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      height: screenHeight * .70,
      child: Column(
        children: [
          // Drag Merchant
          Container(
              height: 5,
              width: 50,
              margin: const EdgeInsets.only(top: 10, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              )),

          const SizedBox(height: 15),

          ValueListenableBuilder<List<ScanResult>>(
            valueListenable: scanResults,
            builder: (context, scanResultsValue, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 15),
                  Text(
                    "CloudCast:  ",
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        color: Colors.white54, // Set text color to white
                        fontSize: 20, // Font size
                        fontWeight: FontWeight.bold, // Bold weight
                      ),
                    ),
                  ),
                  //const SizedBox(width: 10),
                  const Icon(Icons.cloud, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    scanResultsValue.length.toString(), // Connection count
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                          color: Colors.white54,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 15),
                ],
              );
            },
          ),

          // Device List or Status Message
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 75, top: 20),
              child: ValueListenableBuilder<bool>(
                valueListenable: isLoading,
                builder: (context, isLoadingValue, _) {
                  if (isLoadingValue) {
                    // Render loading indicator when `isLoading` is true
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    );
                  }
                  // Render the ListView.builder when `isLoading` is false
                  return ValueListenableBuilder<List<ScanResult>>(
                    valueListenable: scanResults,
                    builder: (context, scanResultsValue, _) {
                      if (scanResultsValue.isNotEmpty) {
                        return ListView.builder(
                          itemCount: scanResultsValue.length,
                          itemBuilder: (context, index) {
                            final result = scanResultsValue[index];
                            final String advName =
                                result.advertisementData.advName;

                            // Extract the merchantId and alpha character from the advertisement name
                            final String merchantId = advName.split('~').first;
                            final String alphaCharacter =
                                advName.split('~')[1].split('|').first;

                            // Access the LocalDatabase to fetch the Merchant object
                            final localDatabase = Provider.of<LocalDatabase>(
                                context,
                                listen: false);
                            final Merchant? merchant =
                                localDatabase.merchants[int.parse(merchantId)];

                            // Define display values
                            final String displayTitle = merchant != null
                                ? "${merchant.nickname ?? 'Unknown Tag'} - $alphaCharacter"
                                : "Unknown Merchant";
                            final String displaySubtitle =
                                merchant?.name ?? "No name available";

                            return Container(
                              width: MediaQuery.of(context).size.width,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 13, horizontal: 10),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                leading: merchant?.logoImg != null
                                    ? CircleAvatar(
                                        backgroundImage:
                                            NetworkImage(merchant!.logoImg!),
                                        radius: 25, // Adjust the size as needed
                                      )
                                    : const CircleAvatar(
                                        backgroundColor: Colors.grey,
                                        child: Icon(Icons.image,
                                            color: Colors
                                                .white), // Placeholder icon
                                      ),
                                title: Text(
                                  displayTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  displaySubtitle,
                                  style: const TextStyle(color: Colors.white54),
                                ),
                                trailing: const SizedBox(
                                  width: 40, // Adjust to fit your needs
                                  child: SpinKitThreeBounce(
                                    color: Colors.white,
                                    size: 25.0, // Adjust to fit your needs
                                  ),
                                ),
                                onTap: () async {
                                  isLoading.value =
                                      true; // Show loading indicator
                                  try {
                                    // Extract the advertisement name before attempting pairing
                                    final String advName =
                                        result.advertisementData.advName;

                                    // Extract the merchant Id (string before the `~`) from the advertisement name
                                    final String merchantId =
                                        advName.split('~').first;

                                    if (merchantId.isNotEmpty) {
                                      debugPrint(
                                          'Extracted merchant Id: $merchantId');

                                      // Use the Provider to access the Customer class
                                      final database =
                                          Provider.of<LocalDatabase>(context,
                                              listen: false);

                                      // Trigger fetchTagsAndItems with the merchant Id
                                      await database.fetchCategoriesAndItems(
                                          int.parse(merchantId));
                                    } else {
                                      debugPrint(
                                          'No valid merchant Id found in advertisement name: $advName');
                                    }

                                    // Proceed with pairing logic
                                    await attemptPairing(result);
                                    debugPrint(
                                        'Tapped on device: ${result.device.platformName}');
                                  } finally {
                                    isLoading.value =
                                        false; // Hide loading indicator
                                  }
                                },
                                splashColor:
                                    Colors.transparent, // Disable ripple color
                                hoverColor: Colors.transparent,
                              ),
                            );
                          },
                        );
                      } else {
                        // No devices found or status messages
                        return ValueListenableBuilder<String>(
                          valueListenable: bluetoothStatus,
                          builder: (context, status, _) {
                            if (status == "Bluetooth permissions denied") {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 100.0),
                                child: Center(
                                  child: GestureDetector(
                                    onTap: openAppSettings,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 24),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        "Open Settings",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            } else if (status == "Bluetooth is off") {
                              return const Center(
                                child: Text(
                                  "Bluetooth is off",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              );
                            } else {
                              return const Center(
                                child: Text(
                                  "No Devices Found",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              );
                            }
                          },
                        );
                      }
                    },
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> attemptPairing(ScanResult result) async {
    const String readCharacteristicUuid =
        "d973f26e-8da7-4a96-a7d6-cbca9f2d9a7e";
    final device = result.device;

    try {
      debugPrint(
          'Attempting to connect to ${device.platformName} (${device.remoteId})');
      await device.connect(timeout: const Duration(seconds: 10));
      debugPrint('Connected to ${device.platformName}');

      // Discover services and characteristics
      final services = await device.discoverServices();
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == readCharacteristicUuid) {
            debugPrint(
                'Matched read characteristic UUID: ${characteristic.uuid}');

            // Read the serialized JSON data
            final response = await characteristic.read();
            final responseString = String.fromCharCodes(response);
            debugPrint('Received data: $responseString');

            await device.disconnect();

            // Process the received data
            processReceivedData(responseString);
          }
        }
      }
      debugPrint('Read characteristic not found.');
    } catch (e, stackTrace) {
      debugPrint('Error during pairing: $e');
      debugPrint('Stack Trace: $stackTrace');
      await device.disconnect();
    }
  }

  void processReceivedData(String responseString) async {
    try {
      // Parse the JSON response into a Map<String, dynamic>
      final Map<String, dynamic> parsedResponse = jsonDecode(responseString);

      // Extract the merchantId
      final String id = parsedResponse['id'].toString();

      final int merchantId = int.parse(id.replaceAll(RegExp(r'[^\d]'), ''));
      final String terminalId = id.replaceAll(
          RegExp(r'[\d]'), ''); // Keep only non-digits for terminalId

      // Log the results
      debugPrint('Extracted merchantId: $merchantId');
      debugPrint('Extracted terminalId: $terminalId');

      // Extract the cartItems
      final List<dynamic> cartItems = parsedResponse['order'] ?? [];

      // Construct the list of ItemOrder objects
      final List<ItemOrder> itemOrders = cartItems.map((item) {
        final int itemId = item['itemId'] ?? 0;
        final int quantity = item['quantity'] ?? 0;
        const String paymentType = "regular"; // Default value for paymentType

        // Return a ItemOrder object
        return ItemOrder(
          itemId, // itemId
          '', // itemName (placeholder)
          paymentType, // paymentType
          quantity, // quantity
        );
      }).toList();

      // Create the CustomerOrder object
      final CustomerOrder order = CustomerOrder(
        '', // name
        0, // merchantId
        0, // customerId
        0.0, // totalRegularPrice
        false, // inAppPayments
        itemOrders, // items
        '', // status
        '', // claimer
        0, // timestamp
        '', // sessionId
      );

      debugPrint('Created CustomerOrder: $order');

      final cart = Cart();
      cart.setMerchant(merchantId);
      cart.reorder(order);

      await Navigator.of(context).pushNamed(
        '/menu',
        arguments: {
          'merchantId': merchantId,
          'cart': cart,
          'itemId': order.items.first.itemId, // Optional itemId.
          'terminal': terminalId
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Error processing received data: $e');
      debugPrint('Stack Trace: $stackTrace');
    }
  }

  void clearBLE() async {
    try {
      FlutterBluePlus.stopScan().catchError((error) {
        debugPrint("Error stopping scan: $error");
      });

      scanSubscription?.cancel().catchError((error) {
        debugPrint("Error canceling scan subscription: $error");
      });

      scanSubscription = null;
      isScanning.value = false;
      scanResults.value = [];
      debugPrint("Scanning has been completely stopped.");

      if (scanResults.value.isEmpty) {
        debugPrint('No devices to disconnect.');
        return;
      }

      for (final result in scanResults.value) {
        try {
          final device = result.device;
          debugPrint(
              'Attempting to disconnect from ${device.platformName} (${device.remoteId})');
          await device.disconnect();
          debugPrint('Successfully disconnected from ${device.platformName}');
        } catch (e) {
          debugPrint(
              'Error disconnecting from ${result.device.platformName}: $e');
        }
      }
    } catch (e) {
      debugPrint("Error in stopScanning: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint("AppLifecycleState: $state");
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      debugPrint("App paused. Stopping scan and cleaning up.");
      clearBLE();
    } else if (state == AppLifecycleState.resumed) {
      debugPrint("App resumed. Rechecking Bluetooth permissions.");
      requestBluetoothPermissions();
    }
  }

  @override
  void dispose() {
    debugPrint("Disposing MerchantBottomSheet...");
    clearBLE();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
