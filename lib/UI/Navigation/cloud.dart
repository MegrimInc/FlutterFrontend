import 'dart:async';
import 'dart:convert';
import 'dart:io'; // For platform checks
import 'package:cached_network_image/cached_network_image.dart';
import 'package:megrim/Backend/database.dart';
import 'package:megrim/DTO/employee.dart';
import 'package:megrim/DTO/items.dart';
import 'package:megrim/DTO/merchant.dart';
import 'package:megrim/Backend/cart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:megrim/DTO/transaction.dart';
import 'package:megrim/UI/BrowsePage/browse.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class CloudPage extends StatefulWidget {
  final Transaction? transaction;

  const CloudPage({super.key, this.transaction});

  @override
  State<CloudPage> createState() => _BlueTooth();
}

class _BlueTooth extends State<CloudPage> with WidgetsBindingObserver {
  final ValueNotifier<String> bluetoothStatus =
      ValueNotifier("Checking Bluetooth permissions...");
  final ValueNotifier<bool> isScanning = ValueNotifier(false);
  final ValueNotifier<List<ScanResult>> scanResults = ValueNotifier([]);
  StreamSubscription? scanSubscription;
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final _pageController = PageController(initialPage: 5000);
  int _currentPageIndex = 0;
  late final Transaction? transaction;

  @override
  void initState() {
    super.initState();
    transaction = widget.transaction;
    debugPrint('CloudPage opened with transaction: $transaction');
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
        final RegExp namePattern = RegExp(r'^\d+&\d+\*(cc|cl)\|');

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
              height: 7,
              width: 50,
              margin: const EdgeInsets.only(top: 10, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              )),

          const SizedBox(height: 8),

          _buildHeaderSwitcher(),

          // The main content area
          Expanded(
            // ✨ Step 1: Wrap the content area in a GestureDetector
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                // Check swipe direction and animate the PageController in the header
                if (details.primaryVelocity! > 200) {
                  // Swiped Left
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else if (details.primaryVelocity! < -200) {
                  // Swiped Right
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              // A transparent container to ensure the gesture is detected over the whole area
              child: Container(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 75, top: 20),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: isLoading,
                    builder: (context, isLoadingValue, _) {
                      if (isLoadingValue) {
                        return const Center(
                            child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white)));
                      }

                      // ✨ Step 2: Use an AnimatedSwitcher for the instant swap effect
                      return AnimatedSwitcher(
                        duration:
                            const Duration(milliseconds: 250), // A quick fade
                        child:
                            _buildConditionalContent(), // A new helper for clarity
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the header with looping arrows and the PageView.
  Widget _buildHeaderSwitcher() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: screenWidth * 0.025),
            IconButton(
              icon: const Icon(Icons.fast_rewind_rounded,
                  size: 30, color: Colors.white54),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
            Expanded(
              child: SizedBox(
                height: 40,
                child: ValueListenableBuilder<List<ScanResult>>(
                  valueListenable: scanResults,
                  builder: (context, scanResultsValue, _) {
                    // Count cl and cc separately
                    final clCount = scanResultsValue
                        .where((r) => RegExp(r'^\d+&\d+\*cl\|')
                            .hasMatch(r.advertisementData.advName))
                        .length;

                    final ccCount = scanResultsValue
                        .where((r) => RegExp(r'^\d+&\d+\*cc\|')
                            .hasMatch(r.advertisementData.advName))
                        .length;

                    return PageView.builder(
                      controller: _pageController,
                      itemCount: 10000,
                      physics: const ClampingScrollPhysics(),
                      onPageChanged: (page) {
                        if (mounted) {
                          setState(() {
                            _currentPageIndex = page % 2;
                          });
                        }
                      },
                      itemBuilder: (context, index) {
                        final isCloudLinkPage = (index % 2 == 0);
                        final label =
                            isCloudLinkPage ? "CloudLink" : "CloudCast";
                        final count = isCloudLinkPage ? clCount : ccCount;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("$label:  ",
                                style: GoogleFonts.poppins(
                                    textStyle: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold))),
                            const Icon(Icons.cloud, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(count.toString(),
                                style: GoogleFonts.poppins(
                                    textStyle: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold))),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.fast_forward_rounded,
                  size: 30, color: Colors.white54),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onPressed: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
            SizedBox(width: screenWidth * 0.025),
          ],
        ),
      ],
    );
  }

  Widget _buildConditionalContent() {
    return ValueListenableBuilder<List<ScanResult>>(
      key: ValueKey<String>('content_$_currentPageIndex'),
      valueListenable: scanResults,
      builder: (context, scanResultsValue, _) {
        if (scanResultsValue.isEmpty) {
          return _buildStatusUI();
        }

        if (_currentPageIndex == 0) {
          // CloudLink tab
          final clResults = scanResultsValue
              .where((r) => RegExp(r'^\d+&\d+\*cl\|')
                  .hasMatch(r.advertisementData.advName))
              .toList();

          return clResults.isEmpty
              ? _buildStatusUI()
              : _buildCloudLinkScanResults(clResults);
        } else {
          // CloudCast tab
          final ccResults = scanResultsValue
              .where((r) => RegExp(r'^\d+&\d+\*cc\|')
                  .hasMatch(r.advertisementData.advName))
              .toList();

          return ccResults.isEmpty
              ? _buildStatusUI()
              : _buildCloudCastScanResults(ccResults);
        }
      },
    );
  }

  // Widget _buildCloudLinkScanResults(List<ScanResult> scanResultsValue) {
  //   return ListView.builder(
  //     itemCount: scanResultsValue.length,
  //     itemBuilder: (context, index) {
  //       final double itemHeight = MediaQuery.of(context).size.height * 0.13;

  //       final double avatarRadius = itemHeight * 0.33;
  //       final double spinnerSize = itemHeight * 0.25;
  //       final result = scanResultsValue[index];
  //       final String advName = result.advertisementData.advName;
  //       final List<String> starSplit = advName.split('*');
  //       if (starSplit.length < 2) return const SizedBox.shrink();
  //       final String idPart = starSplit[0];
  //       final List<String> idSplit = idPart.split('&');
  //       if (idSplit.length < 2) return const SizedBox.shrink();

  //       final String merchantIdStr = idSplit[0];
  //       final String employeeIdStr = idSplit[1];

  //       final int? parsedMerchantId = int.tryParse(merchantIdStr);
  //       if (parsedMerchantId == null) {
  //         return const SizedBox.shrink();
  //       }

  //       final int? parsedEmployeeId = int.tryParse(employeeIdStr);

  //       final localDatabase =
  //           Provider.of<LocalDatabase>(context, listen: false);
  //       final Merchant? merchant = localDatabase.merchants[parsedMerchantId];

  //       final Employee? employee =
  //           localDatabase.findEmployeeById(parsedMerchantId, parsedEmployeeId!);

  //       final String? profileImage =
  //           (employee?.image != null && employee!.image!.isNotEmpty)
  //               ? employee.image
  //               : null;

  //       final String merchantName = merchant != null
  //           ? merchant.nickname ?? 'Unknown Tag'
  //           : "Unknown Merchant";

  //       return GestureDetector(
  //         onTap: () async {
  //           isLoading.value = true;
  //           try {
  //             await attemptPairingForCloudLink(result); // ← await here
  //           } finally {
  //             isLoading.value = false;
  //           }
  //         },
  //         child: Container(
  //           height: itemHeight,
  //           width: MediaQuery.of(context).size.width,
  //           margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
  //           padding: const EdgeInsets.all(8),
  //           decoration: BoxDecoration(
  //             color: Colors.white24,
  //             borderRadius: BorderRadius.circular(10),
  //           ),
  //           // We no longer need the Center widget
  //           child: Row(
  //             children: [
  //               SizedBox(width: MediaQuery.of(context).size.width * .025),
  //               // --- 1. The Leading Avatar ---
  //               merchant?.image != null && merchant!.image!.isNotEmpty
  //                   ? CircleAvatar(
  //                       backgroundImage: CachedNetworkImageProvider("$profileImage"),
  //                       radius: avatarRadius,
  //                     )
  //                   : CircleAvatar(
  //                       backgroundColor: Colors.grey,
  //                       radius: avatarRadius,
  //                       child: Icon(Icons.image,
  //                           color: Colors.white, size: avatarRadius),
  //                     ),

  //               // --- 2. The Space Between ---
  //               SizedBox(width: MediaQuery.of(context).size.width * .03),

  //               // --- 3. The Title and Subtitle Block ---
  //               Expanded(
  //                 child: Column(
  //                   mainAxisAlignment: MainAxisAlignment
  //                       .center, // Vertically centers the texts
  //                   crossAxisAlignment:
  //                       CrossAxisAlignment.start, // Left-aligns the texts
  //                   children: [
  //                     Text(
  //                       "@$merchantName",
  //                       style: TextStyle(
  //                         color: Colors.white,
  //                         fontWeight: FontWeight.w600,
  //                       ),
  //                     ),
  //                     const SizedBox(
  //                         height: 4), // Small gap between title and subtitle
  //                     Text(
  //                       (employee != null &&
  //                               employee.name != null &&
  //                               employee.name!.isNotEmpty)
  //                           ? employee.name!
  //                           : "...",
  //                       style: TextStyle(
  //                         color: Colors.white54,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),

  //               // --- 4. The Trailing Spinner ---
  //               SizedBox(
  //                 width: spinnerSize * 2,
  //                 child: SpinKitThreeBounce(
  //                   color: Colors.white,
  //                   size: spinnerSize,
  //                 ),
  //               ),
  //               SizedBox(width: MediaQuery.of(context).size.width * .03)
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildCloudLinkScanResults(List<ScanResult> scanResultsValue) {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: scanResultsValue.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: .9,
      ),
      itemBuilder: (context, index) {
        final result = scanResultsValue[index];
        final String advName = result.advertisementData.advName;
        final List<String> starSplit = advName.split('*');
        if (starSplit.length < 2) return const SizedBox.shrink();
        final String idPart = starSplit[0];
        final List<String> idSplit = idPart.split('&');
        if (idSplit.length < 2) return const SizedBox.shrink();

        final String merchantIdStr = idSplit[0];
        final String employeeIdStr = idSplit[1];
        final int? parsedMerchantId = int.tryParse(merchantIdStr);
        final int? parsedEmployeeId = int.tryParse(employeeIdStr);
        if (parsedMerchantId == null || parsedEmployeeId == null) {
          return const SizedBox.shrink();
        }

        final localDatabase =
            Provider.of<LocalDatabase>(context, listen: false);
        final Merchant? merchant = localDatabase.merchants[parsedMerchantId];
        final Employee? employee =
            localDatabase.findEmployeeById(parsedMerchantId, parsedEmployeeId);
        final String? profileImage =
            (employee?.image?.isNotEmpty ?? false) ? employee!.image : null;
        final String merchantName = merchant?.nickname ?? 'Unknown Tag';

        return GestureDetector(
          onTap: () async {
            isLoading.value = true;
            try {
              await attemptPairingForCloudLink(result);
            } finally {
              isLoading.value = false;
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 5),
              CircleAvatar(
                backgroundImage: profileImage != null
                    ? CachedNetworkImageProvider(profileImage)
                    : null,
                backgroundColor: Colors.grey,
                radius: 60,
                child: profileImage == null
                    ? const Icon(Icons.image, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 8),
               Text(
                "@$merchantName",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
              Text(
                (employee?.name?.isNotEmpty ?? false)
                    ? employee!.name!.toLowerCase()
                    : "...",
                style: const TextStyle(
                    color: Colors.white54, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCloudCastScanResults(List<ScanResult> scanResultsValue) {
    return ListView.builder(
      itemCount: scanResultsValue.length,
      itemBuilder: (context, index) {
        final double itemHeight = MediaQuery.of(context).size.height * 0.13;

        final double avatarRadius = itemHeight * 0.33;
        final double spinnerSize = itemHeight * 0.25;
        final result = scanResultsValue[index];
        final String advName = result.advertisementData.advName;
        final List<String> starSplit = advName.split('*');
        if (starSplit.length < 2) return const SizedBox.shrink();
        final String idPart = starSplit[0];
        final List<String> idSplit = idPart.split('&');
        if (idSplit.length < 2) return const SizedBox.shrink();

        final String merchantIdStr = idSplit[0];
        final String employeeIdStr = idSplit[1];

        final int? parsedMerchantId = int.tryParse(merchantIdStr);
        if (parsedMerchantId == null) {
          return const SizedBox.shrink();
        }

        final int? parsedEmployeeId = int.tryParse(employeeIdStr);

        final localDatabase =
            Provider.of<LocalDatabase>(context, listen: false);
        final Merchant? merchant = localDatabase.merchants[parsedMerchantId];

        final Employee? employee =
            localDatabase.findEmployeeById(parsedMerchantId, parsedEmployeeId!);

        final String? profileImage =
            (employee?.image != null && employee!.image!.isNotEmpty)
                ? employee.image
                : null;

        final String merchantName = merchant != null
            ? merchant.nickname ?? 'Unknown Tag'
            : "Unknown Merchant";

        return GestureDetector(
          onTap: () async {
            isLoading.value = true;
            try {
              if (merchantIdStr.isNotEmpty) {
                await localDatabase.fetchCategoriesAndItems(parsedMerchantId);
              }
              await attemptPairingForCloudCast(result);
            } finally {
              isLoading.value = false;
            }
          },
          child: Container(
            height: itemHeight,
            width: MediaQuery.of(context).size.width,
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
            // We no longer need the Center widget
            child: Row(
              children: [
                SizedBox(width: MediaQuery.of(context).size.width * .025),
                // --- 1. The Leading Avatar ---
                merchant?.image != null && merchant!.image!.isNotEmpty
                    ? CircleAvatar(
                        backgroundImage:
                            CachedNetworkImageProvider("$profileImage"),
                        radius: avatarRadius,
                      )
                    : CircleAvatar(
                        backgroundColor: Colors.grey,
                        radius: avatarRadius,
                        child: Icon(Icons.image,
                            color: Colors.white, size: avatarRadius),
                      ),

                // --- 2. The Space Between ---
                SizedBox(width: MediaQuery.of(context).size.width * .03),

                // --- 3. The Title and Subtitle Block ---
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment
                        .center, // Vertically centers the texts
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Left-aligns the texts
                    children: [
                      Text(
                        "@$merchantName",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(
                          height: 4), // Small gap between title and subtitle
                      Text(
                        (employee != null &&
                                employee.name != null &&
                                employee.name!.isNotEmpty)
                            ? employee.name!
                            : "...",
                        style: TextStyle(
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- 4. The Trailing Spinner ---
                SizedBox(
                  width: spinnerSize * 2,
                  child: SpinKitThreeBounce(
                    color: Colors.white,
                    size: spinnerSize,
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * .03)
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusUI() {
    return ValueListenableBuilder<String>(
      valueListenable: bluetoothStatus,
      builder: (context, status, _) {
        if (status == "Bluetooth permissions denied") {
          // ✨ THIS IS THE FIX ✨
          // We now provide all 3 required arguments to our helper widget
          return _buildPermissionRequestUI(
            "Bluetooth permission is required to find nearby devices.", // 1. The explanation text
            "Open Settings", // 2. The button text
            openAppSettings, // 3. The function to call
          );
        } else if (status == "Bluetooth is off") {
          return const Center(
            child: Text(
              "Bluetooth is turned off",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        } else {
          // If the status is anything else (like 'granted' but no devices yet)
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

  Widget _buildPermissionRequestUI(
      String text, String buttonText, VoidCallback onPressed) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.bluetooth_disabled, color: Colors.grey, size: 80),
            const SizedBox(height: 20),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onPressed,
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> attemptPairingForCloudCast(ScanResult result) async {
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

  Future<void> attemptPairingForCloudLink(ScanResult result) async {
    const String readCharacteristicUuid =
        "b0869404-e0aa-40b2-ab60-4262709c6fbb";
    final device = result.device;

    try {
      // 1. Connect
      await device.connect(timeout: const Duration(seconds: 10));

      // 2. Discover services & characteristics
      final services = await device.discoverServices();
      for (final service in services) {
        for (final c in service.characteristics) {
          if (c.uuid.toString() == readCharacteristicUuid) {
            // 3. Read
            final response = await c.read();
            final responseString = String.fromCharCodes(response);
            debugPrint('Pairing got: $responseString');

            // 4. Disconnect asap
            await device.disconnect();

            // 5. Parse: expecting "merchantId&employeeId"
            final parts = responseString.trim().split('&');
            if (parts.length == 2) {
              final int? merchantId = int.tryParse(parts[0]);
              final int? employeeId = int.tryParse(parts[1]);

              if (merchantId != null && employeeId != null && mounted) {
                final cart = Cart();
                cart.setMerchant(merchantId);

                if (transaction != null) {
                  if (transaction!.merchantId == merchantId) {
                    debugPrint('Merchant IDs match, using transaction items');

                    await Navigator.of(context).pushNamed(
                      '/items',
                      arguments: {
                        'merchantId': merchantId,
                        'cart': cart,
                        'items': transaction!.items,
                        'employeeId': employeeId,
                        'pointOfSale': "cloudlink"
                      },
                    );
                    return;
                  } else {
                    debugPrint(
                        'Merchant IDs did not match, aborting special navigation.');
                    return;
                  }
                }

                await Navigator.push(
                  // ignore: use_build_context_synchronously
                  context,
                  MaterialPageRoute(
                    builder: (context) => BrowsePage(
                      merchantId: merchantId,
                      employeeId: employeeId,
                      pointOfSale: "cloudlink",
                      cart: cart,
                    ),
                  ),
                );
              }
            } else {
              debugPrint("Unexpected BLE response: $responseString");
            }
            return;
          }
        }
      }
      // if we fall through without finding the characteristic:
      await device.disconnect();
    } catch (e) {
      debugPrint('Error in attemptPairingForCloudLink: $e');
      try {
        await device.disconnect();
      } catch (_) {}
    }
  }

  void processReceivedData(String responseString) async {
    try {
      // Parse the JSON response into a Map<String, dynamic>
      final Map<String, dynamic> parsedResponse = jsonDecode(responseString);

      // Extract the merchantId
      final String id = parsedResponse['id'].toString();

      // Split by '&' and parse both IDs
      final parts = id.split('&');
      final int merchantId = int.parse(parts[0]);
      final int employeeId = int.parse(parts[1]);

      // Log the results
      debugPrint('Extracted merchantId: $merchantId');
      debugPrint('Extracted employeeId: $employeeId');

      // Extract the cartItems
      final List<dynamic> cartItems = parsedResponse['order'] ?? [];

      // Construct the list of ItemOrder objects
      final List<Items> itemOrders = cartItems.map((item) {
        final int itemId = item['itemId'] ?? 0;
        final int quantity = item['quantity'] ?? 0;
        const String paymentType = "regular"; // Default value for paymentType

        // Return a ItemOrder object
        return Items(
          itemId: itemId,
          itemName: '',
          paymentType: paymentType,
          quantity: quantity,
        );
      }).toList();

      final cart = Cart();
      cart.setMerchant(merchantId);

      await Navigator.of(context).pushNamed(
        '/items',
        arguments: {
          'merchantId': merchantId,
          'cart': cart,
          'items': itemOrders.isNotEmpty ? itemOrders : null,
          'employeeId': employeeId,
          'pointOfSale': "cloudcast"
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
    _pageController.dispose();
    super.dispose();
  }
}
