// ignore_for_file: use_build_context_synchronously

import 'package:another_flushbar/flushbar.dart';
import 'package:barzzy/Backend/merchanthistory.dart';
import 'package:barzzy/Backend/item.dart';
import 'package:barzzy/Backend/preferences.dart';
import 'package:barzzy/MenuPage/cart.dart';
import 'package:barzzy/MenuPage/itemfeed.dart';
import 'package:barzzy/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../Backend/merchant.dart';
import '../Backend/localdatabase.dart';

class MenuPage extends StatefulWidget {
  final String merchantId;
  final Cart cart;
  final String? itemId;
  final String? claimer;

  const MenuPage({
    super.key,
    required this.merchantId,
    required this.cart,
    this.itemId,
    this.claimer,
  });

  @override
  MenuPageState createState() => MenuPageState();
}

class MenuPageState extends State<MenuPage>
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

    if (widget.itemId != null) {
      final localDatabase =
          LocalDatabase(); // This retrieves the singleton instance.
      final item = localDatabase.getItemById(widget.itemId!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(
          _createRoute(item, widget.cart, targetPage: 1,),
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
        'LocalDatabase instance in MenuPage: ${LocalDatabase().hashCode}');
    if (currentMerchant != null) {
      appBarTitle = (currentMerchant!.tag ?? 'Menu Page').replaceAll(' ', '');
    }

    await Provider.of<Category>(context, listen: false)
        .fetchTagsAndItems(widget.merchantId);
    debugPrint('Finished fetching items for merchantId: ${widget.merchantId}');
    debugPrint(
        'LocalDatabase instance in MenuPage: ${LocalDatabase().hashCode}');

    await sendGetRequest2();

    setState(() {
      isLoading = false;
    });
    final merchantHistory = Provider.of<MerchantHistory>(context, listen: false);
    merchantHistory.setTappedMerchantId(widget.merchantId);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.cart,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
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
            child: Consumer<Category>(
              builder: (context, customer, _) {
                final randomItems = customer.getFullItemListByMerchantId(widget.merchantId);
                // Inside your _buildMainContent method or wherever you're using it
                return Column(
                  children: [
                    const SizedBox(height: 25),
                    if (randomItems['tag179']?.isNotEmpty ?? false) ...[
                      _buildItemSection(
                          context, 'Lager', randomItems['tag179']!),
                      const SizedBox(height: 50),
                    ],
                    if (randomItems['tag172']?.isNotEmpty ?? false) ...[
                      _buildItemSection(
                          context, 'Vodka', randomItems['tag172']!),
                      const SizedBox(height: 50),
                    ],
                    if (randomItems['tag175']?.isNotEmpty ?? false) ...[
                      _buildItemSection(
                          context, 'Tequila', randomItems['tag175']!),
                      const SizedBox(height: 50),
                    ],
                    if (randomItems['tag174']?.isNotEmpty ?? false) ...[
                      _buildItemSection(
                          context, 'Whiskey', randomItems['tag174']!),
                      const SizedBox(height: 50),
                    ],
                    if (randomItems['tag173']?.isNotEmpty ?? false) ...[
                      _buildItemSection(
                          context, 'Gin', randomItems['tag173']!),
                      const SizedBox(height: 50),
                    ],
                    if (randomItems['tag176']?.isNotEmpty ?? false) ...[
                      _buildItemSection(
                          context, 'Brandy', randomItems['tag176']!),
                      const SizedBox(height: 50),
                    ],
                    if (randomItems['tag177']?.isNotEmpty ?? false) ...[
                      _buildItemSection(
                          context, 'Rum', randomItems['tag177']!),
                      const SizedBox(height: 50),
                    ],
                    if (randomItems['tag186']?.isNotEmpty ?? false) ...[
                      _buildItemSection(
                          context, 'Seltzer', randomItems['tag186']!),
                      const SizedBox(height: 50),
                    ],
                    if (randomItems['tag178']?.isNotEmpty ?? false) ...[
                      _buildItemSection(
                          context, 'Ale', randomItems['tag178']!),
                      const SizedBox(height: 50),
                    ],
                    if (randomItems['tag183']?.isNotEmpty ?? false) ...[
                      _buildItemSection(
                          context, 'Red Wine', randomItems['tag183']!),
                      const SizedBox(height: 50),
                    ],
                    if (randomItems['tag184']?.isNotEmpty ?? false) ...[
                      _buildItemSection(
                          context, 'White Wine', randomItems['tag184']!),
                      const SizedBox(height: 50),
                    ],
                    if (randomItems['tag181']?.isNotEmpty ?? false) ...[
                      _buildItemSection(
                          context, 'Virgin', randomItems['tag181']!),
                      const SizedBox(height: 50),
                    ],
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
            color: Colors.grey.withOpacity(0.3),
            width: 0.25,
          ),
        ),
        color: Colors.black, // Removed gradient
      ),
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 16.0),
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
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Consumer<Cart>(
            builder: (context, cart, _) {
              return IconButton(
                icon: const Icon(
                  FontAwesomeIcons.solidStar,
                  color: Colors.white,
                  size: 17.5,
                ),
                onPressed: () {
                  Flushbar(
                    messageText: Row(
                      children: [
                        const Spacer(),
                        const Icon(Icons.star, color: Colors.white),
                        const SizedBox(width: 7),
                        Text(
                          "You have ${cart.merchantPoints} points!",
                          style: const TextStyle(
                            color: Colors.white, // Customize the message color
                            fontSize: 16,
                          ),
                          textAlign: TextAlign
                              .center, // Ensure the text is centered within the widget
                        ),
                        const Spacer(),
                      ],
                    ),
                    backgroundColor: Colors.black,
                    duration: const Duration(seconds: 1),
                    flushbarPosition: FlushbarPosition.TOP,
                    borderRadius: BorderRadius.circular(8),
                    margin: const EdgeInsets.all(10),
                  ).show(context);
                },
              );
            },
          ),
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
                          .getItemById(itemId.toString());

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
                                            color:
                                                Colors.black.withOpacity(0.6),
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
    debugPrint("MenuPage: Passing claimer = ${widget.claimer}"); 
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => ItemFeed(
        item: item,
        cart: cart,
        merchantId: widget.merchantId,
        initialPage: targetPage,
        claimer: widget.claimer,
      ),
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