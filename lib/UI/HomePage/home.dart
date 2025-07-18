import 'dart:convert';
import 'package:megrim/DTO/merchant.dart';
import 'package:megrim/UI/AuthPages/RegisterPages/logincache.dart';
import 'package:megrim/Backend/database.dart';
import 'package:megrim/Backend/websocket.dart';
import 'package:megrim/UI/ChatPage/chat.dart';
import 'package:megrim/UI/LeaderboardPage/leaderboard.dart';
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
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

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
  Style? _style;

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
      builder: (context) => LeaderboardPage(
        onClose: () => entry.remove(),
        customerId: customerId,
        merchantId: merchantId,
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
  void _loadMapData() async {
    try {
      // Load the style from your server
      final newStyle = await StyleReader(
        uri: 'http://54.147.153.13/styles/dark-matter/style.json',
      ).read();

      // Once the style is loaded, prepare the map data for the markers
      final mapDataFuture = _prepareMapData();

      if (mounted) {
        setState(() {
          _style = newStyle;
          _mapDataFuture = mapDataFuture;
        });
      }
    } catch (e) {
      debugPrint('Error setting up map: $e');
    }
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
    if (_permissionStatus == null || _style == null) {
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

            return FlutterMap(
              options: MapOptions(
                initialCenter: userLocation,
                initialZoom: 19,
                backgroundColor: Colors.black,
                minZoom: 2,
                maxZoom: 22.0,
                cameraConstraint: CameraConstraint.contain(
                  bounds: LatLngBounds(const LatLng(-85.0511, -180.0),
                      const LatLng(85.0511, 180.0)),
                ),
              ),
              children: [

                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  retinaMode: true,
                  userAgentPackageName: 'site.megrim.app',
                ),

                // VectorTileLayer(
                //   theme: _style!.theme,
                //   tileProviders: TileProviders({
                //     'openmaptiles': NetworkVectorTileProvider(
                //       urlTemplate:
                //           'http://54.147.153.13/data/openmaptiles/{z}/{x}/{y}.pbf',
                //     ),
                //   }),
                // ),

                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 45,
                    size: const Size(40, 40),
                    markers: geocodedMerchants.map((record) {
                      final merchant = record.merchant;
                      final coordinates = record.coordinates;
                      return Marker(
                        point: coordinates,
                        width: 105,
                        height: 95,
                        child: _buildMerchantMarker(merchant),
                      );
                    }).toList(),
                    builder: (context, markers) {
                      return Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withAlpha(200),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          '${markers.length}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
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

  Widget _buildMerchantMarker(Merchant merchant) {
    return GestureDetector(
        onTap: () => showCardsOverlay(merchant.merchantId!),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (merchant.storeImg != null && merchant.storeImg!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: Image.network(
                  merchant.storeImg!,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 3),
            Text(
              "@${merchant.nickname ?? 'No Tag'}",
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ));
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
