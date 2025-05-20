import 'package:barzzy/Backend/database.dart';
import 'package:barzzy/Backend/cart.dart';
import 'package:barzzy/UI/CatalogPage/catalog.dart';
import 'package:barzzy/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';


class BankPage extends StatefulWidget {
  const BankPage({super.key});

  @override
  State<BankPage> createState() => _BankPageState();
}

class _BankPageState extends State<BankPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    // Listen for focus changes
    _focusNode.addListener(() {
      setState(() {}); // Triggers rebuild on focus change
    });
  }

  Future<void> _refreshData() async {
    // Call sendGetRequest2 to fetch the latest data
    await sendGetPoints();
    setState(() {}); // Rebuild the UI with the new data
  }

  @override
  Widget build(BuildContext context) {
    final localDatabase = Provider.of<LocalDatabase>(context, listen: false);

    // Calculate the total points
    final totalPoints = localDatabase
        .getSearchableMerchantInfo()
        .keys
        .map((merchantId) => localDatabase.getPointsForMerchant(merchantId)?.points ?? 0)
        .fold(0, (sum, points) => sum + points);

    final filteredMerchants = localDatabase.getSearchableMerchantInfo().entries.where(
      (entry) {
        final name = entry.value['name'] ?? '';
        return name.toLowerCase().contains(_searchText.toLowerCase());
      },
    ).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header with "Bank" and Total Points
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'B-A-N-K',
                    style: GoogleFonts.megrim(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$totalPoints pts',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50),
            // Search Merchant
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey, // Color of the border
                    width: .09, // Thickness of the border
                  ),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7.5),
                    child: _buildSearchBar(),
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // List of Merchants
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                color: Colors.black,
                child: ListView.separated(
                  itemCount: filteredMerchants.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final merchantId = filteredMerchants[index].key;
                    final merchantName =
                        filteredMerchants[index].value['name'] ?? 'Unknown';
                    final points =
                        localDatabase.getPointsForMerchant(merchantId)?.points ?? 0;
                    final tagImage = LocalDatabase.getMerchantById(merchantId)?.storeImg ??
                        'https://www.barzzy.site/images/default.png';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) {
                            Cart cart = Cart();
                            cart.setMerchant(merchantId);

                            return CatalogPage(
                              merchantId: merchantId,
                              cart: cart,
                            );
                          },
                        ));
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.transparent,
                          backgroundImage:
                              CachedNetworkImageProvider(tagImage),
                        ),
                        title: Text(
                          '$merchantName - $points pts',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildSearchBar() {
  return Container(
    height: 50,
    decoration: BoxDecoration(
      color: Colors.grey[900],
      borderRadius: BorderRadius.circular(10),
    ),
    child: TextField(
      controller: _searchController,
      focusNode: _focusNode,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      textAlignVertical: TextAlignVertical.center, // Ensure vertical centering
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        border: InputBorder.none,
        hintText: 'Search... ',
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear, color: Colors.white),
          onPressed: () {
            setState(() {
              _searchController.clear();
              _searchText = '';
            });
          },
        ),
      ),
      onChanged: (text) {
        setState(() {
          _searchText = text;
        });
      },
    ),
  );
}

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}