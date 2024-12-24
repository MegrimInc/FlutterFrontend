import 'dart:async';
import 'dart:io'; // For platform checks
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

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

   final targetServiceUuid = Guid("25f7d535-ab21-4ae5-8d0b-adfae5609005");
                                
  // Listen to scan results
  scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
    // Temporary map to hold filtered results by service UUID
    final Map<String, ScanResult> filteredResults = {};

    for (final result in results) {
      // Check if the target service UUID is in the advertisement data
      final advertisedServiceUuids = result.advertisementData.serviceUuids;
      if (advertisedServiceUuids.contains(targetServiceUuid)) {
        filteredResults[result.device.remoteId.toString()] = result;
      }
    }

    // Update current results with new filtered results
    for (final entry in filteredResults.entries) {
      currentResults[entry.key] = entry.value;
    }

    // Remove devices that are no longer being scanned
    final scannedDeviceIds = filteredResults.keys.toSet();
    currentResults.removeWhere((id, _) => !scannedDeviceIds.contains(id));

    // Update the scanResults ValueNotifier with the sorted list
    scanResults.value = currentResults.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi)); // Sort by signal strength

    debugPrint("Updated scan results: ${scanResults.value.length} devices found.");
  });

  // Start scanning without a timeout
  FlutterBluePlus.startScan().catchError((error) {
    debugPrint("Error starting scan: $error");
    isScanning.value = false; // Reset scanning state in case of an error
  });

  debugPrint("Scanning started indefinitely with live result updates and service filtering.");
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
              color: Colors.grey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
          ),

          const SizedBox(height: 50),

          // Device List or Status Message
          Expanded(
            child: ValueListenableBuilder<List<ScanResult>>(
              valueListenable: scanResults,
              builder: (context, scanResultsValue, _) {
                if (scanResultsValue.isNotEmpty) {
                  // Show list of scanned devices
                  return ListView.builder(
                    itemCount: scanResultsValue.length,
                    itemBuilder: (context, index) {
                      final result = scanResultsValue[index];
                      return ListTile(
                          leading:
                              const Icon(Icons.bluetooth, color: Colors.blue),
                          title: Text(
                            result.advertisementData.advName.isNotEmpty
                                ? result.advertisementData.advName
                                : "Unknown Device",
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            result.device.remoteId.toString(),
                            style: const TextStyle(color: Colors.grey),
                          ),
                          onTap: () {
                            attemptPairing(
                                result); // Pass the 'result' object here
                            debugPrint(
                                'Tapped on device: ${result.device.platformName}');
                          });
                    },
                  );
                } else {
                  // No devices found or status messages
                  return ValueListenableBuilder<String>(
                    valueListenable: bluetoothStatus,
                    builder: (context, status, _) {
                      if (status == "Bluetooth permissions denied") {
                        return Center(
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
                        );
                      } else if (status == "Bluetooth is off") {
                        return const Center(
                          child: Text(
                            "Bluetooth is off",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        );
                      } else {
                        return const Center(
                          child: Text(
                            "No Devices Found",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        );
                      }
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

 Future<void> attemptPairing(ScanResult result) async {
  const String readCharacteristicUuid = "d973f26e-8da7-4a96-a7d6-cbca9f2d9a7e";
  const String writeCharacteristicUuid = "6b18f42b-c62d-4e5c-9d4c-53c90b4ad5cc";
  
  try {
    final device = result.device;

    debugPrint('Attempting to connect to ${device.platformName} (${device.remoteId})');
    await device.connect(timeout: const Duration(seconds: 10));
    debugPrint('Connected to ${device.platformName}');

    // Discover services and characteristics
    final services = await device.discoverServices();

    // Attempt to find the read and write characteristics
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (characteristic.uuid.toString() == readCharacteristicUuid) {
          debugPrint('Matched read characteristic UUID: ${characteristic.uuid}');
          // Read the secretCode
          final response = await characteristic.read();
          final secretCode = int.parse(String.fromCharCodes(response));
          debugPrint('Received secretCode: $secretCode');

          // Calculate expected value
          const multiplier = 73490286;
          final expectedValue = secretCode * multiplier;

          // Find the write characteristic and send the expected value
          for (final char in service.characteristics) {
            if (char.uuid.toString() == writeCharacteristicUuid) {
              await char.write(expectedValue.toString().codeUnits, withoutResponse: true);
              debugPrint('Sent expectedValue: $expectedValue');
              return; // Exit after successful write
            }
          }
          debugPrint('Write characteristic not found.');
        }
      }
    }
    debugPrint('Read characteristic not found.');
  } catch (e) {
    debugPrint('Error during pairing: $e');
  }
}

  void stopScanning() {
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
      stopScanning();
    } else if (state == AppLifecycleState.resumed) {
      debugPrint("App resumed. Rechecking Bluetooth permissions.");
      requestBluetoothPermissions();
    }
  }

  @override
  void dispose() {
    debugPrint("Disposing BarBottomSheet...");
    stopScanning();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
