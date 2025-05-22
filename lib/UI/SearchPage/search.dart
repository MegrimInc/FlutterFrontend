import 'package:megrim/Backend/searchengine.dart';
import 'package:megrim/Backend/cart.dart';
import 'package:megrim/UI/SearchPage/searchbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:megrim/UI/CatalogPage/catalog.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  Map<int, Map<String, String>> _filteredMerchants = {};
  final FocusNode _focusNode = FocusNode();

  void _handleSearchChanged(String searchText) {
    final searchService = Provider.of<SearchService>(context, listen: false);
    Map<int, Map<String, String>> filteredMerchants =
        searchService.searchMerchants(searchText);

    setState(() {
      _filteredMerchants = filteredMerchants;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Search(
              onSearchChanged: _handleSearchChanged,
              focusNode: _focusNode,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredMerchants.length,
                itemBuilder: (context, index) {
                  int merchantId = _filteredMerchants.keys.elementAt(index);
                  Map<String, String> merchantInfo = _filteredMerchants[merchantId]!;
                  String displayText =
                      "${merchantInfo['name']} - ${merchantInfo['address']}";
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    tileColor: Colors.transparent,
                    leading:
                        const Icon(Icons.chevron_right, color: Colors.white),
                    title: Text(
                      displayText,
                      style: GoogleFonts.sourceSans3(color: Colors.grey),
                    ),
                   onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) {
        // Create a new Cart instance
        Cart cart = Cart();
        cart.setMerchant(merchantId); // Set the merchant Id for the cart

        // Pass the newly created Cart instance to the MenuPage
        return CatalogPage(
          merchantId: merchantId,
          cart: cart,
        );
      },
    ),
  );
},
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
}