import 'dart:async';
import 'dart:convert';
import 'dart:io'; // For platform checks
import 'package:barzzy/Backend/bar.dart';
import 'package:barzzy/Backend/customer_order.dart';
import 'package:barzzy/Backend/localdatabase.dart';
import 'package:barzzy/Backend/preferences.dart';
import 'package:barzzy/MenuPage/cart.dart';
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

    // Listen to scan results
    scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        final String advName = result.advertisementData.advName;
      final RegExp namePattern = RegExp(r'^\d+~[A-Z]\|');
        

        // Only include devices advertising with "Peripheral" in their name
        if (advName.isNotEmpty && namePattern.hasMatch(advName)) {
          currentResults[result.device.remoteId.toString()] = result;
        }
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
          // Drag Bar
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
    padding: const EdgeInsets.only(bottom: 75),
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
                  final String advName = result.advertisementData.advName;
    
                  // Extract the barId and alpha character from the advertisement name
                  final String barId = advName.split('~').first;
                  final String alphaCharacter =
                      advName.split('~')[1].split('|').first;
    
                  // Access the LocalDatabase to fetch the Bar object
                  final localDatabase =
                      Provider.of<LocalDatabase>(context, listen: false);
                  final Bar? bar = localDatabase.bars[barId];
    
                  // Define display values
                  final String displayTitle = bar != null
                      ? "${bar.tag ?? 'Unknown Tag'} - $alphaCharacter"
                      : "Unknown Bar";
                  final String displaySubtitle =
                      bar?.name ?? "No name available";
    
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.symmetric(
                        vertical: 30, horizontal: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: bar?.tagimg != null
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(bar!.tagimg!),
                              radius: 25, // Adjust the size as needed
                            )
                          : const CircleAvatar(
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.image,
                                  color: Colors.white), // Placeholder icon
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
                        isLoading.value = true; // Show loading indicator
                        try {
                          // Extract the advertisement name before attempting pairing
                          final String advName =
                              result.advertisementData.advName;
    
                          // Extract the bar ID (string before the `~`) from the advertisement name
                          final String barId = advName.split('~').first;
    
                          if (barId.isNotEmpty) {
                            debugPrint('Extracted bar ID: $barId');
    
                            // Use the Provider to access the User class
                            final user =
                                Provider.of<User>(context, listen: false);
    
                            // Trigger fetchTagsAndDrinks with the bar ID
                            await user.fetchTagsAndDrinks(barId);
                          } else {
                            debugPrint(
                                'No valid bar ID found in advertisement name: $advName');
                          }
    
                          // Proceed with pairing logic
                          await attemptPairing(result);
                          debugPrint(
                              'Tapped on device: ${result.device.platformName}');
                        } finally {
                          isLoading.value = false; // Hide loading indicator
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
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    );
                  } else {
                    return const Center(
                      child: Text(
                        "No Devices Found",
                        style: TextStyle(color: Colors.white, fontSize: 16),
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

      // Extract the barId
      final String id = parsedResponse['id'].toString();

      // Separate the barId and bartenderId
      final String barId =
          id.replaceAll(RegExp(r'[^\d]'), ''); // Keep only digits for barId
      final String bartenderId = id.replaceAll(
          RegExp(r'[\d]'), ''); // Keep only non-digits for bartenderId

      // Log the results
      debugPrint('Extracted barId: $barId');
      debugPrint('Extracted bartenderId: $bartenderId');

      // Extract the cartItems
      final List<dynamic> cartItems = parsedResponse['order'] ?? [];

      // Construct the list of DrinkOrder objects
      final List<DrinkOrder> drinkOrders = cartItems.map((item) {
        final int drinkId = item['drinkId'] ?? 0;
        final int quantity = item['quantity'] ?? 0;
        final String sizeType =
            item['sizeType'] ?? ""; // Default to empty string
        const String paymentType = "regular"; // Default value for paymentType

        // Return a DrinkOrder object
        return DrinkOrder(
          drinkId, // drinkId
          '', // drinkName (placeholder)
          paymentType, // paymentType
          sizeType, // sizeType
          quantity, // quantity
        );
      }).toList();

      // Create the CustomerOrder object
      final CustomerOrder order = CustomerOrder(
        '', // name
        '', // barId
        0, // userId
        0.0, // totalRegularPrice
        0.0, // tip
        false, // inAppPayments
        drinkOrders, // drinks
        '', // status
        '', // claimer
        0, // timestamp
        '', // sessionId
      );

      debugPrint('Created CustomerOrder: $order');

      final cart = Cart();
      cart.setBar(barId);
      cart.reorder(order);

      await Navigator.of(context).pushNamed(
        '/menu',
        arguments: {
          'barId': barId,
          'cart': cart,
          'drinkId': order.drinks.first.drinkId.toString(), // Optional drinkId.
          'claimer' : bartenderId
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
    debugPrint("Disposing BarBottomSheet...");
    clearBLE();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
