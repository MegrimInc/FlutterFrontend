import 'dart:convert';
import 'package:megrim/DTO/merchant.dart';
import 'package:megrim/UI/AuthPages/RegisterPages/logincache.dart';
import 'package:megrim/Backend/database.dart';
import 'package:megrim/Backend/websocket.dart';
import 'package:megrim/UI/ChatPage/chat.dart';
import 'package:megrim/UI/WalletPage/wallet.dart';
import 'package:megrim/UI/SearchPage/searchpage.dart';
import 'package:megrim/config.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/heroicons_solid.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late double screenHeight;
  late double bottomHeight;
  late double paddingHeight;
  late Future<(LatLng, List<({Merchant merchant, LatLng coordinates})>)>
      _mapDataFuture;
  LocationPermission? _permissionStatus;

  @override
  void initState() {
    super.initState();
    _connect();
    checkPaymentMethod();
    //sendGetPoints();
    _checkLocationPermission();
  }

  Future<void> _connect() async {
    final hierarchy = Provider.of<Websocket>(context, listen: false);
    hierarchy.connect(context); // No need to await since it returns void
  }

  Future<void> checkPaymentMethod() async {
    LocalDatabase localDatabase = LocalDatabase();
    LoginCache loginCache = LoginCache();
    final customerId = await loginCache.getUID();

    if (customerId == 0) {
      debugPrint('Customer Id is 0, skipping GET request for payment method.');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            '${AppConfig.postgresHttpBaseUrl}/customer/checkPaymentMethod/$customerId'),
      );

      if (response.statusCode == 200) {
        final paymentPresent = jsonDecode(response.body); // true or false
        debugPrint('Payment method check result: $paymentPresent');

        if (paymentPresent == true) {
          localDatabase.updatePaymentStatus(PaymentStatus.present);
        } else {
          localDatabase.updatePaymentStatus(PaymentStatus.notPresent);
        }
      } else {
        debugPrint(
            'Failed to check payment method. Status code: ${response.statusCode}');
        localDatabase.updatePaymentStatus(PaymentStatus.notPresent);
      }
    } catch (e) {
      debugPrint('Error checking payment method: $e');
      localDatabase.updatePaymentStatus(PaymentStatus.notPresent);
    }
  }

  void showCardsOverlay(int merchantId) async {
    // ✨ Change 1: Added merchantId as a parameter
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    final customerId = await LoginCache().getUID();

    if (customerId == 0) return;

    // The rest of the function now uses the merchantId we passed in
    entry = OverlayEntry(
      builder: (context) => WalletPage(
        onClose: () => entry.remove(),
        customerId: customerId,
        merchantId: merchantId,
        isBlack: false, //TODO: CHANGE TO DYNAMIC
      ),
    );

    overlay.insert(entry);
  }

  /// Checks the current location permission status using Geolocator.
  Future<void> _checkLocationPermission() async {
    // First, check if location services are even enabled on the device
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // If services are disabled, we treat it as denied for the UI
      setState(() => _permissionStatus = LocationPermission.denied);
      return;
    }

    // Check the permission status
    final status = await Geolocator.checkPermission();
    setState(() {
      _permissionStatus = status;
    });

    if (status == LocationPermission.whileInUse ||
        status == LocationPermission.always) {
      _loadMapData();
    }
  }

  /// Requests location permission from the user using Geolocator.
  Future<void> _requestLocationPermission() async {
    final status = await Geolocator.requestPermission();
    setState(() {
      _permissionStatus = status;
    });

    if (status == LocationPermission.whileInUse ||
        status == LocationPermission.always) {
      _loadMapData();
    }
  }

  /// This function now only runs AFTER permission is granted.
  void _loadMapData() {
    setState(() {
      _mapDataFuture = _prepareMapData();
    });
  }

  Future<(LatLng, List<({Merchant merchant, LatLng coordinates})>)>
      _prepareMapData() async {
    final userPosition = await _determinePosition();
    //final userLatLng = LatLng(userPosition.latitude, userPosition.longitude);
    final userLatLng = const LatLng(37.229572, -80.413940);

    final allMerchants = LocalDatabase().merchants.values.toList();

    var geocodedMerchants = <({Merchant merchant, LatLng coordinates})>[];
    for (final merchant in allMerchants) {
      try {
        final addressString =
            '${merchant.address}, ${merchant.city}, ${merchant.stateOrProvince} ${merchant.zipCode}';
        final locations = await locationFromAddress(addressString);
        if (locations.isEmpty) {
          // nothing found for this address, skip to next merchant
          continue;
        }
        final loc = locations.first;
        geocodedMerchants.add((
          merchant: merchant,
          coordinates: LatLng(loc.latitude, loc.longitude)
        ));
      } catch (e) {
        debugPrint('Could not geocode merchant ${merchant.name}: $e');
      }
    }
    // Return the final record
    return (userLatLng, geocodedMerchants);
  }

  /// Determines the current position of the device using Geolocator.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }
    return await Geolocator.getCurrentPosition();
  }

  void _refreshMap() {
    setState(() {
      _mapDataFuture = _prepareMapData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.black,
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
            elevation: 2,
            title: Row(
              children: [
                GestureDetector(
                  onTap: _refreshMap, // Calls our new function
                  child: Text(
                    'H o m e',
                    style: GoogleFonts.megrim(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 25,
                      shadows: [],
                    ),
                  ),
                ),

                const Spacer(),

                //SEARCH

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchPage(),
                      ),
                    );
                  },
                  child: const Iconify(
                    HeroiconsSolid.search,
                    size: 25,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(width: 15),

                GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ChatPage()),
                      );
                    },
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(math.pi),
                      child: const Icon(
                        Icons.chat,
                        size: 25.5,
                        color: Colors.grey,
                      ),
                    )),
              ],
            )),
        body: _buildBody(),
        bottomNavigationBar: FutureBuilder<int>(
          future: Provider.of<LoginCache>(context, listen: false).getUID(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink(); // Return nothing while waiting
            }
            if (snapshot.hasData && snapshot.data == 0) {
              return Container(
                height: bottomHeight,
                width: double.infinity, // Ensures full-width alignment
                decoration: const BoxDecoration(
                  color: Colors.black, // Background color for better visibility
                  border: Border(
                    top: BorderSide(
                      color: Color.fromARGB(255, 126, 126, 126),
                      width: 0.1,
                    ),
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: paddingHeight),
                    child: const Text(
                      '⚠️   WARNING: VIEW ONLY   ⚠️',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox
                .shrink(); // Return nothing if customerId is not 0
          },
        ));
  }

  Widget _buildBody() {
    // While we're first checking, show a loader
    if (_permissionStatus == null) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }

    switch (_permissionStatus!) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        // If permission is granted, show the FutureBuilder and the map
        return FutureBuilder<
            (LatLng, List<({Merchant merchant, LatLng coordinates})>)>(
          future: _mapDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                !snapshot.hasData) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red)));
            }
            final userLocation = snapshot.data!.$1;
            final geocodedMerchants = snapshot.data!.$2;

            // Create a lookup map for easy access to coordinates by ID
            final merchantLocations = {
              for (var record in geocodedMerchants)
                record.merchant.merchantId: record.coordinates
            };

            // Define the points for our line
            final List<LatLng> connectionPoints = [];

            // Get the locations for the specific merchants we want to connect
            final LatLng? location1 = merchantLocations[95]; // ID for @theburg
            final LatLng? location2 = merchantLocations[94]; // ID for @centros

            // If both locations were found, add them to our list
            if (location1 != null && location2 != null) {
              connectionPoints.addAll([location1, location2]);
            }

            return FlutterMap(
              options: MapOptions(
                initialCenter: userLocation,
                initialZoom: 18,
                backgroundColor: Colors.black,
                minZoom: 2,
                maxZoom: 20.0,
                cameraConstraint: CameraConstraint.contain(
                  bounds: LatLngBounds(const LatLng(-85.0511, -180.0),
                      const LatLng(85.0511, 180.0)),
                ),
              ),
              children: [
                // Layer 1: The dark-themed base map
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  retinaMode: true,
                  userAgentPackageName: 'site.megrim.app',
                ),

                if (connectionPoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: connectionPoints,
                        color: Colors.green,
                        strokeWidth: 1.0,
                      ),
                    ],
                  ),

                // Layer 2: The markers for all your businesses
                MarkerLayer(
                  markers: geocodedMerchants.map((record) {
                    // Access data from the inner record
                    final merchant = record.merchant;
                    final coordinates = record.coordinates;

                    return Marker(
                      point: coordinates,
                      width: 121,
                      height: 30,
                      child: GestureDetector(
                        onTap: () => showCardsOverlay(merchant.merchantId!),
                        child: Container(
                          color: Colors.transparent,
                          child: Center(
                            child: Text(
                              "@${merchant.nickname ?? 'No Tag'}",
                              softWrap: false,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        );

      case LocationPermission.denied:
        return _buildPermissionRequestUI(
          "Megrim uses your location to show you nearby places.",
          "Allow Location",
          _requestLocationPermission,
        );

      case LocationPermission.deniedForever:
        return _buildPermissionRequestUI(
          "Location permissions have been denied. Please enable it in your device settings to use the map.",
          "Open Settings",
          Geolocator.openAppSettings, // Geolocator has a helper for this!
        );

      // This case handles `unableToDetermine`
      default:
        return _buildPermissionRequestUI(
          "Could not determine location permission. Please try again.",
          "Check Permission",
          _checkLocationPermission,
        );
    }
  }

  /// A reusable widget for the permission request UI.
  Widget _buildPermissionRequestUI(
      String text, String buttonText, VoidCallback onPressed) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, color: Colors.grey, size: 80),
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
              ),
              onPressed: onPressed,
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Dynamically calculate the available screen height
    screenHeight = MediaQuery.of(context).size.height -
        (3.8 * kToolbarHeight); // Subtract twice the AppBar height
    bottomHeight = (MediaQuery.of(context).size.height - screenHeight) * .5;
    paddingHeight = bottomHeight * .18;
  }
}
