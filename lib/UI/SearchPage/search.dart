import 'package:flutter/services.dart';
import 'package:megrim/Backend/database.dart';
import 'package:megrim/UI/AuthPages/RegisterPages/logincache.dart';
import 'package:megrim/UI/InfoPage/info.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
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
      builder: (context) => InfoPage(
        onClose: () => entry.remove(),
        customerId: customerId,
        merchantId: merchantId,
      ),
    );

    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final localDatabase = Provider.of<LocalDatabase>(context, listen: false);
    final filteredMerchants =
        localDatabase.getSearchableMerchantInfo().entries.where(
      (entry) {
        final name = entry.value['name'] ?? '';
        return name.toLowerCase().contains(_searchText.toLowerCase());
      },
    ).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey,
                      width: .1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.05,
                    ),
                    Text(
                      'S e a r c h',
                      style: GoogleFonts.megrim(
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.search, color: Colors.grey, size: 29),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.05,
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.only(
                  left: MediaQuery.of(context).size.width * 0.03,
                  right: MediaQuery.of(context).size.width * 0.03,
                  top: MediaQuery.of(context).size.height * 0.03,
                  bottom: MediaQuery.of(context).size.height * 0.05
                ),
                child: _buildSearchBar(),
              ),

              // List of Merchants
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: .75,
                  ),
                  itemCount: filteredMerchants.length,
                  itemBuilder: (context, index) {
                    final merchantId = filteredMerchants[index].key;
                    final merchant = LocalDatabase.getMerchantById(merchantId);
                    filteredMerchants[index].value['name'] ?? 'Unknown';
                    final merchantName =
                        (merchant?.nickname?.isNotEmpty ?? false)
                            ? merchant!.nickname!
                            : (merchant?.name?.isNotEmpty ?? false)
                                ? merchant!.name!
                                : 'Unknown';
                    final tagImage = (merchant?.image?.isNotEmpty ?? false)
                        ? merchant!.image!
                        : 'https://www.barzzy.site/images/default.png';
                              
                    return GestureDetector(
                      onTap: () => showCardsOverlay(merchantId),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: CachedNetworkImage(
                              imageUrl: tagImage,
                              width: double.infinity,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "@$merchantName",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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
        textAlignVertical:
            TextAlignVertical.center, // Ensure vertical centering
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
          border: InputBorder.none,
          hintText: '@... ',
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 20),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear, color: _searchController.text.isEmpty ? Colors.transparent : Colors.white),
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
