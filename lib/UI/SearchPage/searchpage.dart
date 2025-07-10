import 'package:megrim/Backend/searchengine.dart';
import 'package:megrim/UI/AuthPages/RegisterPages/logincache.dart';
import 'package:megrim/UI/SearchPage/searchbar.dart';
import 'package:flutter/material.dart';
import 'package:megrim/UI/WalletPage/wallet.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchPage extends StatefulWidget {
  final bool autoFocus;
  const SearchPage({super.key, this.autoFocus = false});

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

  void showCardsOverlay(int merchantId) async {
    _focusNode.unfocus();

    if (!mounted) return;

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
                  Map<String, String> merchantInfo =
                      _filteredMerchants[merchantId]!;
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
                    onTap: () => showCardsOverlay(merchantId),
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
    _focusNode.unfocus(); // Ensure keyboard is dismissed
    _focusNode.dispose();
    super.dispose();
  }
}
