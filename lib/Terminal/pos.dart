import 'dart:math';
import 'dart:typed_data';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class POSPage extends StatefulWidget {
  const POSPage({super.key});

  @override
  State<POSPage> createState() => _POSPageState();
}

class _POSPageState extends State<POSPage> {
  final PeripheralManager _peripheralManager = PeripheralManager();
  final Uuid uuid = const Uuid();
  static const String predefinedServiceUuid = "25f7d535-ab21-4ae5-8d0b-adfae5609005";
  final int secretCode = Random().nextInt(9000) + 1000; // Generate a 4-digit number
  final int multiplier = 73490286; // Fixed multiplier
  late final int expectedValue; // Calculated product
  final ValueNotifier<String> statusNotifier = ValueNotifier("Waiting for connection...");
  late GATTService _gattService;
  late GATTCharacteristic _gattCharacteristic;
  bool isBroadcasting = false;
  bool isDeviceConnected = false;

  @override
  void initState() {
    super.initState();
    debugPrint("POSPage widget initialized.");
    expectedValue = secretCode * multiplier;
     debugPrint("Expected value (secretCode * multiplier): $expectedValue");
    _requestPermissions();
    _initializePeripheral();
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
  }

  Future<void> _initializePeripheral() async {
    debugPrint("Initializing peripheral...");
    final generatedUuid = uuid.v4();
    debugPrint("Generated UUID: $generatedUuid");

    final uuidBytes = _stringToBytes(generatedUuid);
    debugPrint("Converted UUID to bytes: $uuidBytes");

    _gattCharacteristic = GATTCharacteristic.mutable(
      uuid: UUID(uuidBytes),
      properties: [
        GATTCharacteristicProperty.read,
        GATTCharacteristicProperty.write,
        GATTCharacteristicProperty.notify,
      ],
      permissions: [
        GATTCharacteristicPermission.read,
        GATTCharacteristicPermission.write,
      ],
      descriptors: [],
    );
    debugPrint("GATT characteristic created.");

    _gattService = GATTService(
      uuid: UUID(uuidBytes),
      characteristics: [_gattCharacteristic],
      isPrimary: true,
      includedServices: [],
    );
    debugPrint("GATT service created.");

    await _peripheralManager.addService(_gattService);
    debugPrint("GATT service added to peripheral.");
    _peripheralManager.characteristicReadRequested.listen(_onReadRequest);
    _peripheralManager.characteristicWriteRequested.listen(_onWriteRequest);
  }

  
  Future<void> _onReadRequest(GATTCharacteristicReadRequestedEventArgs args) async {
    debugPrint("Read request received.");
    final responseValue = Uint8List.fromList(secretCode.toString().codeUnits); // Send secretCode
    await _peripheralManager.respondReadRequestWithValue(
      args.request,
      value: responseValue,
    );
    debugPrint("Read request responded with: $secretCode");
  }

  Future<void> _onWriteRequest(GATTCharacteristicWriteRequestedEventArgs args) async {
    final writtenValue = args.request.value;
    debugPrint("Write request received with value: $writtenValue");

    // Convert the received bytes to an integer
    final receivedValue = int.tryParse(String.fromCharCodes(writtenValue));
    debugPrint("Converted received value: $receivedValue");

    if (receivedValue == expectedValue) {
      debugPrint("Verification successful!");
      statusNotifier.value = "Authorized device connected!";
    } else {
      debugPrint("Verification failed! Disconnecting...");
      statusNotifier.value = "Unauthorized device! Connection rejected.";
      await _stopAdvertising(); // Disconnect if the device is unauthorized
    }

    await _peripheralManager.respondWriteRequest(args.request);
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

    final advertisement = Advertisement(
      name: "BarzzyPOS", // iOS supports name in advertisements
      serviceUUIDs: [
        UUID(_stringToBytes(predefinedServiceUuid)) // Add service UUID if needed
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
    return Center(
      child: ElevatedButton(
        onPressed: _toggleAdvertising,
        style: ElevatedButton.styleFrom(
          backgroundColor: isBroadcasting ? Colors.red : Colors.green,
        ),
        child: Text(
          isBroadcasting ? "Stop Advertising" : "Start Advertising",
          style: const TextStyle(color: Colors.white),
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
    debugPrint("Clean UUID: $cleanUuid");

    final byteBuffer = List<int>.generate(cleanUuid.length ~/ 2, (i) {
      final byte = int.parse(cleanUuid.substring(i * 2, i * 2 + 2), radix: 16);
      debugPrint("Parsed byte: $byte");
      return byte;
    });

    final byteList = Uint8List.fromList(byteBuffer);
    debugPrint("Final byte list: $byteList");
    return byteList;
  }

  @override
  void dispose() {
    debugPrint("POSPage widget disposed.");
    _stopAdvertising();
    super.dispose();
  }
}
