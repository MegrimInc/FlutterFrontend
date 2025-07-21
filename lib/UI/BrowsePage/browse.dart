// ignore_for_file: use_build_context_synchronously

import 'package:megrim/Backend/database.dart';
import 'package:megrim/DTO/item.dart';
import 'package:megrim/Backend/cart.dart';
import 'package:megrim/DTO/items.dart';
import 'package:megrim/UI/CheckoutPage/checkout.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../DTO/merchant.dart';

class BrowsePage extends StatefulWidget {
  final int merchantId;
  final Cart cart;
  final List<Items>? items;
  final int? employeeId;
  final String pointOfSale;

  const BrowsePage(
      {super.key,
      required this.merchantId,
      required this.cart,
      this.items,
      this.employeeId,
      required this.pointOfSale});

  @override
  BrowsePageState createState() => BrowsePageState();
}

class BrowsePageState extends State<BrowsePage>
    with SingleTickerProviderStateMixin {
  String appBarTitle = '';
  bool isLoading = true;
  Merchant? currentMerchant;
  final TextEditingController _searchController = TextEditingController();
  bool hasText = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late AnimationController _animationController;
  final Map<String, PageController> _pageControllers = {};
  final Map<String, int> _currentPageIndices = {};

  @override
  void initState() {
    super.initState();

    _fetchMerchantData();

    if (widget.items != null && widget.employeeId != null) {
      final localDatabase =
          LocalDatabase(); // This retrieves the singleton instance.
      widget.cart.reorder(widget.items!);
      final item = localDatabase.getItemById(widget.items!.first.itemId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(
          _createRoute(
            item,
            widget.cart,
            targetPage: 1,
          ),
        );
      });
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  PageController _getPageController(String tagName) {
    if (!_pageControllers.containsKey(tagName)) {
      _pageControllers[tagName] = PageController();
      _currentPageIndices[tagName] =
          0; // Initialize the page index for the category
    }
    return _pageControllers[tagName]!;
  }

  //LOADS DRINK IN
  Future<void> _fetchMerchantData() async {
    debugPrint('Fetching merchant data for merchantId: ${widget.merchantId}');

    currentMerchant = LocalDatabase.getMerchantById(widget.merchantId);
    debugPrint(
        'LocalDatabase instance in BrowsePage: ${LocalDatabase().hashCode}');
    if (currentMerchant != null) {
      appBarTitle =
          '@${(currentMerchant!.nickname ?? 'Catalog Page').replaceAll(' ', '')}';
    }

    await Provider.of<LocalDatabase>(context, listen: false)
        .fetchCategoriesAndItems(widget.merchantId);
    debugPrint('Finished fetching items for merchantId: ${widget.merchantId}');
    debugPrint(
        'LocalDatabase instance in BrowsePage: ${LocalDatabase().hashCode}');

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.cart,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              _buildMainContent(),
            ],
          ),
        ),
      ),
    );
  }

 Widget _buildMainContent() {
  return Column(
    children: [
      _buildTopBar(),
      Expanded(
        child: SingleChildScrollView(
          key: _listKey,
          controller: _scrollController,
          child: Consumer<LocalDatabase>(
            builder: (context, database, _) {
              final categoryMap = database.getFullItemListByMerchantId(widget.merchantId);
              final sortedEntries = categoryMap.entries.toList()
                ..sort((a, b) {
                  final aId = database.getCategoryIdByName(a.key) ?? 999999;
                  final bId = database.getCategoryIdByName(b.key) ?? 999999;
                  return aId.compareTo(bId);
                });

              return Column(
                children: [
                  const SizedBox(height: 25),
                  for (final entry in sortedEntries)
                    if (entry.value.isNotEmpty) ...[
                      _buildItemSection(context, entry.key, entry.value),
                      const SizedBox(height: 50),
                    ]
                ],
              );
            },
          ),
        ),
      ),
    ],
  );
}

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 0.25,
          ),
        ),
        color: Colors.black, // Removed gradient
      ),
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              FontAwesomeIcons.caretLeft,
              color: Colors.white54,
              size: 25,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Center(
            child: Text(
              appBarTitle,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.more_horiz,
              color: Colors.white54,
              size: 30,
            ),
            onPressed: () {},
          )
        ],
      ),
    );
  }

  Widget _buildItemSection(
      BuildContext context, String tagName, List<int> itemIds) {
    const int itemsPerPage = 9; // Display 9 items per page in a 3x3 grid
    final int pageCount = (itemIds.length / itemsPerPage).ceil();
    final screenHeight = MediaQuery.of(context).size.height;

    double boxHeight;

    if (itemIds.length <= 3) {
      //boxHeight = 150; // Height for 1 row
      boxHeight = screenHeight * 0.19;
    } else if (itemIds.length <= 6) {
      //boxHeight = 300.0; // Height for 2 rows
      boxHeight = screenHeight * 0.37;
    } else {
      //boxHeight = 450; // Height for 3 rows
      boxHeight = screenHeight * 0.55;
    }

    PageController pageController = _getPageController(tagName);

    return Column(
      children: [
        // Display the tag header and page index
        Padding(
          padding: const EdgeInsets.only(bottom: 15, left: 10, right: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tagName,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (pageCount > 1)
                Text(
                  '${_currentPageIndices[tagName]! + 1} / $pageCount',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ),

        // Display the item grid
        SizedBox(
          height: boxHeight,
          child: PageView.builder(
            controller: pageController,
            itemCount: pageCount,
            scrollDirection: Axis.horizontal,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndices[tagName] = index;
              });
            },
            itemBuilder: (context, pageIndex) {
              final startIndex = pageIndex * itemsPerPage;
              final endIndex =
                  (startIndex + itemsPerPage).clamp(0, itemIds.length);

              return GridView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(), // Disable inner scrolling
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 3 columns
                  mainAxisSpacing: 0,
                  crossAxisSpacing: 1.25,
                  childAspectRatio: .85,
                ),
                itemCount: endIndex - startIndex,
                itemBuilder: (context, index) {
                  final itemId = itemIds[startIndex + index];
                  final item =
                      Provider.of<LocalDatabase>(context, listen: false)
                          .getItemById(itemId);

                  return GestureDetector(
                    onTap: () {
                      final cart = Provider.of<Cart>(context, listen: false);
                      Navigator.of(context).push(_createRoute(item, cart));
                      cart.recalculateCartTotals();
                    },
                    child: Column(
                      children: [
                        Flexible(
                          flex: 12,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CachedNetworkImage(
                                    imageUrl: item.image,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned.fill(
                                  child: Consumer<Cart>(
                                    builder: (context, cart, _) {
                                      int itemQuantities = cart
                                          .getTotalQuantityForItem(item.itemId);

                                      if (itemQuantities > 0) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.6),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'x$itemQuantities',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 30,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        );
                                      } else {
                                        return const SizedBox.shrink();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Flexible(
                          flex: 2,
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 5),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Route _createRoute(Item item, Cart cart, {int targetPage = 0}) {
    debugPrint("BrowsePage: Passing employeeId = ${widget.employeeId}");
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => CheckoutPage(
          item: item,
          cart: cart,
          merchantId: widget.merchantId,
          initialPage: targetPage,
          employeeId: widget.employeeId,
          pointOfSale: widget.pointOfSale),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = 0.0;
        var end = 1.0;
        var curve = Curves.easeInOut;

        var scaleTween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var fadeTween =
            Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

        return ScaleTransition(
          scale: animation.drive(scaleTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
