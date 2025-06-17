import 'dart:convert';
import 'package:megrim/DTO/merchant.dart';
import 'package:megrim/UI/AuthPages/RegisterPages/logincache.dart';
import 'package:megrim/Backend/database.dart';
import 'package:megrim/Backend/cart.dart';
import 'package:megrim/Backend/websocket.dart';
import 'package:megrim/UI/ChatPage/chat.dart';
import 'package:megrim/UI/WalletPage/wallet.dart';
import 'package:megrim/UI/SearchPage/searchpage.dart';
import 'package:megrim/config.dart';
import 'package:megrim/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/heroicons_solid.dart';
import 'package:provider/provider.dart';
import 'package:megrim/Backend/history.dart';
import 'package:megrim/UI/CatalogPage/catalog.dart';
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
  late Future<(LatLng, List<({Merchant merchant, LatLng coordinates})>)> _mapDataFuture;

  @override
  void initState() {
    super.initState();
    _connect();
    checkPaymentMethod();
    sendGetPoints();
    _mapDataFuture = _prepareMapData();
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


  void showCardsOverlay() async {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    final customerId = await LoginCache().getUID();
    // ignore: use_build_context_synchronously
    final merchantId = Provider.of<MerchantHistory>(context, listen: false)
        .currentTappedMerchantId;

    if (merchantId == null || customerId == 0) return;

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


    Future<(LatLng, List<({Merchant merchant, LatLng coordinates})>)> _prepareMapData() async {
    final userPosition = await _determinePosition();
    final userLatLng = LatLng(userPosition.latitude, userPosition.longitude);

    final allMerchants = LocalDatabase().merchants.values.toList();
    
    var geocodedMerchants = <({Merchant merchant, LatLng coordinates})>[];
    for (final merchant in allMerchants) {
      try {
        final addressString = '${merchant.address}, ${merchant.city}, ${merchant.stateOrProvince} ${merchant.zipCode}';
        final locations = await locationFromAddress(addressString);
        if (locations.isNotEmpty) {
          final loc = locations.first;
          // Add a record to our list
          geocodedMerchants.add((merchant: merchant, coordinates: LatLng(loc.latitude, loc.longitude)));
        }
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
      if (permission == LocationPermission.denied) return Future.error('Location permissions are denied');
    }
    if (permission == LocationPermission.deniedForever) return Future.error('Location permissions are permanently denied.');
    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.black,
        appBar: AppBar(
            backgroundColor: Colors.black,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
            elevation: 2,
            title: Row(
              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'H o m e',
                  style: GoogleFonts.megrim(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontSize: 25,
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
        body: FutureBuilder<(LatLng, List<({Merchant merchant, LatLng coordinates})>)>(
        future: _mapDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('Finding your location...', style: TextStyle(color: Colors.white)),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Could not load map data.', style: TextStyle(color: Colors.white)));
          }

          // Access data from the record using .$1, .$2, etc.
          final userLocation = snapshot.data!.$1;
          final geocodedMerchants = snapshot.data!.$2;

          return FlutterMap(
            options: MapOptions(
              initialCenter: userLocation,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'site.megrim.app',
              ),
              MarkerLayer(
                markers: geocodedMerchants.map((record) {
                  // Access data from the inner record
                  final merchant = record.merchant;
                  final coordinates = record.coordinates;

                  return Marker(
                    point: coordinates,
                    width: 80,
                    height: 95,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) {
                            Cart cart = Cart();
                            cart.setMerchant(merchant.merchantId!);
                            return CatalogPage(merchantId: merchant.merchantId!, cart: cart);
                          },
                        ));
                      },
                      child: Column(
                        children: [
                          Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.black, width: 2),
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: merchant.storeImg ?? 'https://www.barzzy.site/images/champs/6.png',
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => const Icon(Icons.store, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "@${merchant.nickname ?? 'No Tag'}",
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              backgroundColor: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: userLocation,
                    child: const Icon(Icons.my_location, color: Colors.red, size: 30),
                  ),
                ],
              ),
            ],
          );
        },
      ),
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
}
