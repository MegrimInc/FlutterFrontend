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
  static const String serviceUuid = "25f7d535-ab21-4ae5-8d0b-adfae5609005";
  static const String readCharacteristicUuid = "d973f26e-8da7-4a96-a7d6-cbca9f2d9a7e";
  static const String writeCharacteristicUuid = "6b18f42b-c62d-4e5c-9d4c-53c90b4ad5cc";
  static const String notifyCharacteristicUuid = "2c21e1f7-35a6-469b-900f-c8e3b788e355";
  final int secretCode = Random().nextInt(9000) + 1000; // Generate a 4-digit number
  final int multiplier = 73490286; // Fixed multiplier
  late final int expectedValue; // Calculated product
  final ValueNotifier<String> statusNotifier = ValueNotifier("Waiting for connection...");
  late GATTService _gattService;
  bool isBroadcasting = false;
  bool isDeviceConnected = false;

  @override
  void initState() {
    super.initState();
    debugPrint("POSPage widget initialized.");
    expectedValue = secretCode * multiplier;
     debugPrint("Expected value (secretCode * multiplier): $expectedValue");
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

  // Convert predefined characteristic UUIDs to byte arrays
  final serviceUuidBytes = _stringToBytes(serviceUuid);
  final readCharacteristicBytes = _stringToBytes(readCharacteristicUuid);
  final writeCharacteristicBytes = _stringToBytes(writeCharacteristicUuid);
  final notifyCharacteristicBytes = _stringToBytes(notifyCharacteristicUuid);


  // Define the read characteristic
  final readCharacteristic = GATTCharacteristic.mutable(
    uuid: UUID(readCharacteristicBytes),
    properties: [GATTCharacteristicProperty.read],
    permissions: [GATTCharacteristicPermission.read],
     descriptors: []
  );


  // // Define the write characteristic
  final writeCharacteristic = GATTCharacteristic.mutable(
    uuid: UUID(writeCharacteristicBytes),
    properties: [GATTCharacteristicProperty.write],
    permissions: [GATTCharacteristicPermission.write],
    descriptors: [],
  );

  // // Define the notify characteristic
  final notifyCharacteristic = GATTCharacteristic.mutable(
    uuid: UUID(notifyCharacteristicBytes),
    properties: [GATTCharacteristicProperty.notify],
    permissions: [GATTCharacteristicPermission.read],
    descriptors: [],
  );

  // Define the GATT service
  _gattService = GATTService(
    uuid: UUID(serviceUuidBytes),
    characteristics: [readCharacteristic, writeCharacteristic, notifyCharacteristic],
    isPrimary: true,
    includedServices: [],
  );

  debugPrint("GATT service created.");

  debugPrint("GATT service created with UUID: ${_gattService.uuid}");
  debugPrint("Service characteristics: ${_gattService.characteristics.map((c) => c.uuid.toString()).join(', ')}");

  try {
    await _peripheralManager.addService(_gattService);
    debugPrint("GATT service added successfully");
  } catch (error) {
    debugPrint("Error adding GATT service: $error");
    return;
  }

  // Set up listeners for read and write requests
  _peripheralManager.characteristicReadRequested.listen(_onReadRequest);
  _peripheralManager.characteristicWriteRequested.listen(_onWriteRequest);

  debugPrint("Peripheral initialization completed");
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
