import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:megrim/UI/TerminalPages/inventory.dart';
import 'package:megrim/UI/TerminalPages/select.dart';
import 'package:megrim/UI/TerminalPages/summary.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:megrim/UI/TerminalPages/cloudcast.dart';
import 'package:megrim/UI/TerminalPages/cloudlink.dart';

class Terminal extends StatefulWidget {
  final int employeeId;
  final int merchantId;

  const Terminal(
      {super.key, required this.employeeId, required this.merchantId});
  @override
  State<Terminal> createState() => _TerminalState();
}

class _TerminalState extends State<Terminal> with WidgetsBindingObserver {
  final _pageController = PageController();
  late PeripheralManager _peripheralManager;
  late String serviceUuid;
  late GATTService gattService;
  StreamSubscription? _characteristicReadSubscription;
  bool _isSwitching = false;
  bool _isDisabled = false;
  int _currentPageIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _peripheralManager = PeripheralManager();
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
    _initializePeripheral(_pageController.initialPage);
  }

  Future<void> _initializePeripheral(int pageIndex) async {
    debugPrint("Initializing peripheral...");

    await clearBLE();

    final isCast = pageIndex == 1;
    final readCharacteristicUuid = isCast
        ? "d973f26e-8da7-4a96-a7d6-cbca9f2d9a7e"
        : "b0869404-e0aa-40b2-ab60-4262709c6fbb";

    serviceUuid = isCast
    ? "22222222-2222-2222-2222-222222222222" // CloudCast service
    : "11111111-1111-1111-1111-111111111111"; // CloudLink service

    // serviceUuid = const Uuid().v4();
    // debugPrint("Generated new service UUID: $serviceUuid");

    // Convert predefined characteristic UUIDs to byte arrays
    final serviceUuidBytes = _stringToBytes(serviceUuid);
    final readCharacteristicBytes = _stringToBytes(readCharacteristicUuid);

    // Main Service
    gattService = GATTService(
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

    await _characteristicReadSubscription?.cancel();

    // listen with the right handler
    final handler = isCast ? _onReadRequestCC : _onReadRequestCL;
    _characteristicReadSubscription =
        _peripheralManager.characteristicReadRequested.listen(handler);

    debugPrint("Peripheral initialization completed");

    await _startAdvertising(isCast);
  }

  Future<void> _onReadRequestCL(
      GATTCharacteristicReadRequestedEventArgs args) async {
    debugPrint("Read request received.");

    // Check if the widget is mounted before accessing context
    if (!mounted) {
      debugPrint("Widget is unmounted. Skipping read request processing.");
      return;
    }

    final String response = "${widget.merchantId}&${widget.employeeId}";
    final responseValue = Uint8List.fromList(utf8.encode(response));

    try {
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

  Future<void> _onReadRequestCC(
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
          inv.serializeInventoryCart(inv.inventoryCart, widget.employeeId);

      debugPrint("Serialized inventory cart: $serializedInventory");

      // Convert the serialized inventory to a byte array
      final responseValue =
          Uint8List.fromList(utf8.encode(serializedInventory));

      // Respond to the read request with the serialized data
      await _peripheralManager.respondReadRequestWithValue(
        args.request,
        value: responseValue,
      );

      // **Check if inventory is empty before proceeding**
      if (inv.inventoryCart.isNotEmpty) {
        inv.clearInventory();
        _pageController.animateToPage(
          0, // The target page index
          duration: const Duration(milliseconds: 300), // Animation duration
          curve: Curves.easeInOut, // Animation curve
        );
      }

      debugPrint("Read request responded with inventory data.");
    } catch (error, stackTrace) {
      debugPrint("Error responding to read request: $error");
      debugPrint("Stack trace: $stackTrace");
    }
  }

  Future<void> _startAdvertising(bool isCast) async {
    debugPrint("Attempting to start BLE advertising...");
    final merchantId = widget.merchantId;
    final employeeId = widget.employeeId;
    final suffix = isCast ? "cc" : "cl";

    final advertisement = Advertisement(
      name: "$merchantId&$employeeId*$suffix|${const Uuid().v4()}",
      serviceUUIDs: [
        UUID(_stringToBytes(serviceUuid)) // Add service UUID if needed
      ],
    );

    try {
      await _peripheralManager.startAdvertising(advertisement);
      setState(() => _isDisabled = false);
      debugPrint("BLE advertising started.");
    } catch (e) {
      debugPrint("Error starting BLE advertising: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _disableAdvertising() async {
    try {
      await clearBLE();

      final dummyUuid = const Uuid().v4();
      final dummyAdvert = Advertisement(
        name: dummyUuid,
        serviceUUIDs: [], // no services, purely dummy
      );
      debugPrint("🔒 Disabled: dummy advert $dummyUuid");
      await _peripheralManager.startAdvertising(dummyAdvert);

      setState(() => _isDisabled = true);
    } catch (e) {
      debugPrint("Error starting disabled BLE advertising: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.power_settings_new,
                        color: Colors.redAccent, size: 30),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        // ignore: use_build_context_synchronously
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectPage(),
                        ),
                        (Route<dynamic> route) =>
                            false, // Remove all previous routes
                      );
                    },
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.025,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(2, (pageIndex) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Icon(
                          Icons.circle,
                          color: _currentPageIndex == pageIndex
                              ? Colors.white
                              : Colors.grey,
                          size: 14.5,
                        ),
                      );
                    }),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => SummaryPage(
                          merchantId: widget.merchantId,
                          employeeId: widget.employeeId,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15), // curved edges
                      ),
                      child: const Text(
                        'View Shift',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.024,
                  ),
                  _isLoading
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                              _isDisabled ? Icons.power_off : Icons.power,
                              size: 30),
                          color: Colors.white,
                          onPressed: () {
                            setState(() => _isLoading = true);
                            _isDisabled
                                ? _initializePeripheral(_currentPageIndex)
                                : _disableAdvertising();
                          },
                        ),
                ],
              )
            ],
          ),
        ),
        body: PageView(
          controller: _pageController,
          scrollDirection: Axis.horizontal, // explicitly horizontal
          physics: const BouncingScrollPhysics(),
          pageSnapping: true,
          onPageChanged: _handlePageChanged,
          children: [
            CloudLinkPage(
              employeeId: widget.employeeId,
              merchantId: widget.merchantId,
              pageController: _pageController,
            ),
            CloudCastPage(
              employeeId: widget.employeeId,
              merchantId: widget.merchantId,
              pageController: _pageController,
            ),
          ],
        ),
      ),
    );
  }

  void _handlePageChanged(int pageIndex) {
    setState(() => _currentPageIndex = pageIndex);

    if (_isDisabled) {
      debugPrint("Page change ignored: advertising disabled");
      return;
    }
    // ignore spurious calls or double-swipes
    if (_isSwitching) return;
    _isSwitching = true;

    () async {
      try {
        // 1) completely tear down
        await _initializePeripheral(pageIndex); // 2) bring up new mode
      } finally {
        _isSwitching = false;
      }
    }();
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
      if (_characteristicReadSubscription != null) {
        await _characteristicReadSubscription?.cancel();
        _characteristicReadSubscription = null;
        debugPrint("Characteristic read subscription canceled successfully.");
      }

      // Stop advertising
      await _peripheralManager.stopAdvertising();
      debugPrint("BLE advertising stopped successfully.");

      await _peripheralManager.removeAllServices();
      debugPrint("All BLE services removed successfully.");

    

      // debugPrint("✅ Clear complete");
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
    debugPrint("CloudCastPage widget disposed.");
    WidgetsBinding.instance.removeObserver(this);
    clearBLE();
    super.dispose();
  }
}
