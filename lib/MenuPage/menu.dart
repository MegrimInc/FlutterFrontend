// ignore_for_file: use_build_context_synchronously

import 'package:another_flushbar/flushbar.dart';
import 'package:barzzy/Backend/barhistory.dart';
import 'package:barzzy/Backend/drink.dart';
import 'package:barzzy/Backend/user.dart';
import 'package:barzzy/MenuPage/cart.dart';
import 'package:barzzy/MenuPage/drinkfeed.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../Backend/bar.dart';
import '../Backend/localdatabase.dart';

class MenuPage extends StatefulWidget {
  final String barId;

  const MenuPage({
    super.key,
    required this.barId,
  });

  @override
  MenuPageState createState() => MenuPageState();
}

class MenuPageState extends State<MenuPage>
    with SingleTickerProviderStateMixin {
  String appBarTitle = '';
  bool isLoading = true;
  Bar? currentBar;
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

    debugPrint('are you working or nah');
    _fetchBarData();

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
  Future<void> _fetchBarData() async {
    debugPrint('Fetching bar data for barId: ${widget.barId}');

    currentBar = LocalDatabase.getBarById(widget.barId);
    if (currentBar != null) {
      appBarTitle = (currentBar!.tag ?? 'Menu Page').replaceAll(' ', '');
    }

    await Provider.of<User>(context, listen: false)
        .fetchTagsAndDrinks(widget.barId);
    debugPrint('Finished fetching drinks for barId: ${widget.barId}');

    setState(() {
      isLoading = false;
    });
    final barHistory = Provider.of<BarHistory>(context, listen: false);
    barHistory.setTappedBarId(widget.barId);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        Cart cart = Cart();
        cart.setBar(widget.barId); // Set the bar ID for the cart
        return cart;
      },
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
            child: Consumer<User>(
              builder: (context, user, _) {
                final randomDrinks = user.getFullDrinkListByBarId(widget.barId);
                // Inside your _buildMainContent method or wherever you're using it
                return Column(
                  children: [
                    const SizedBox(height: 25),
                    if (randomDrinks['tag179']?.isNotEmpty ?? false) ...[
                      _buildDrinkSection(
                          context, 'Lager', randomDrinks['tag179']!),
                      //const SizedBox(height: 50),
                    ],
                    if (randomDrinks['tag172']?.isNotEmpty ?? false) ...[
                      _buildDrinkSection(
                          context, 'Vodka', randomDrinks['tag172']!),
                      //const SizedBox(height: 50),
                    ],
                    if (randomDrinks['tag175']?.isNotEmpty ?? false) ...[
                      _buildDrinkSection(
                          context, 'Tequila', randomDrinks['tag175']!),
                      //const SizedBox(height: 50),
                    ],
                    if (randomDrinks['tag174']?.isNotEmpty ?? false) ...[
                      _buildDrinkSection(
                          context, 'Whiskey', randomDrinks['tag174']!),
                      //const SizedBox(height: 50),
                    ],
                    if (randomDrinks['tag173']?.isNotEmpty ?? false) ...[
                      _buildDrinkSection(
                          context, 'Gin', randomDrinks['tag173']!),
                     // const SizedBox(height: 50),
                    ],
                    if (randomDrinks['tag176']?.isNotEmpty ?? false) ...[
                      _buildDrinkSection(
                          context, 'Brandy', randomDrinks['tag176']!),
                      //const SizedBox(height: 50),
                    ],
                    if (randomDrinks['tag177']?.isNotEmpty ?? false) ...[
                      _buildDrinkSection(
                          context, 'Rum', randomDrinks['tag177']!),
                      //const SizedBox(height: 50),
                    ],
                    if (randomDrinks['tag186']?.isNotEmpty ?? false) ...[
                      _buildDrinkSection(
                          context, 'Seltzer', randomDrinks['tag186']!),
                      //const SizedBox(height: 50),
                    ],
                    if (randomDrinks['tag178']?.isNotEmpty ?? false) ...[
                      _buildDrinkSection(
                          context, 'Ale', randomDrinks['tag178']!),
                      //const SizedBox(height: 50),
                    ],
                    if (randomDrinks['tag183']?.isNotEmpty ?? false) ...[
                      _buildDrinkSection(
                          context, 'Red Wine', randomDrinks['tag183']!),
                     // const SizedBox(height: 50),
                    ],
                    if (randomDrinks['tag184']?.isNotEmpty ?? false) ...[
                      _buildDrinkSection(
                          context, 'White Wine', randomDrinks['tag184']!),
                      //const SizedBox(height: 50),
                    ],
                    if (randomDrinks['tag181']?.isNotEmpty ?? false) ...[
                      _buildDrinkSection(
                          context, 'Virgin', randomDrinks['tag181']!),
                      //const SizedBox(height: 50),

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

//   Widget _buildMainContent() {
//   return Column(
//     children: [
//       _buildTopBar(),
//       Expanded(
//         child: SingleChildScrollView(
//           key: _listKey,
//           controller: _scrollController,
//           child: Consumer<User>(
//             builder: (context, user, _) {
//               // Get the sorted drink list based on categories from User
//               final sortedDrinks = user.getFullDrinkListByBarId(widget.barId);

//               // Map for tag IDs to their display names
//               final Map<String, String> tagNames = {
//                 'tag172': 'Vodka',
//                 'tag173': 'Gin',
//                 'tag174': 'Whiskey',
//                 'tag175': 'Tequila',
//                 'tag176': 'Brandy',
//                 'tag177': 'Rum',
//                 'tag178': 'Ale',
//                 'tag179': 'Lager',
//                 'tag181': 'Virgin',
//                 'tag183': 'Red Wine',
//                 'tag184': 'White Wine',
//                 'tag186': 'Seltzer',
//               };

//               // Build the sections dynamically based on the sorted drink list
//               return Column(
//                 children: sortedDrinks.entries.map((entry) {
//                   final tag = entry.key;  // Example: 'tag172'
//                   final drinkIds = entry.value;  // List of drink IDs

//                   // Only build a section if there are drinks for the category
//                   if (drinkIds.isEmpty) return const SizedBox.shrink();

//                   // Get the display name for the tag
//                   final tagName = tagNames[tag] ?? 'Unknown';

//                   return Column(
//                     children: [
//                        const SizedBox(height: 30),
//                       _buildDrinkSection(context, tagName, drinkIds),
//                       const SizedBox(height: 25),
//                     ],
//                   );
//                 }).toList(), // Convert the map entries to a list of widgets
//               );
//             },
//           ),
//         ),
//       ),
//     ],
//   );
// }

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
                  color: Colors.amber,
                  size: 17.5,
                ),
                onPressed: () {
                  Flushbar(
                    messageText: Row(
                      children: [
                        const Spacer(),
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 7),
                        Text(
                          "You have ${cart.barPoints} points!",
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

  Widget _buildDrinkSection(
    BuildContext context, String tagName, List<int> drinkIds) {
  const int itemsPerPage = 9; // Display 9 drinks per page in a 3x3 grid
  final int pageCount = (drinkIds.length / itemsPerPage).ceil();
  //final double boxHeight = 440.0; // Adjusted height to fit 9 items comfortably

 double boxHeight;

if (drinkIds.length <= 3) {
  boxHeight = 210.0; // Height for 1 row
} else if (drinkIds.length <= 6) {
  boxHeight = 350.0; // Height for 2 rows
} else {
  boxHeight = 495.0; // Height for 3 rows
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

      // Display the drink grid
      SizedBox(
        height: boxHeight,
        //color: Colors.red,
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
            final endIndex = (startIndex + itemsPerPage).clamp(0, drinkIds.length);

            return GridView.builder(
              physics: const NeverScrollableScrollPhysics(), // Disable inner scrolling
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3 columns
                mainAxisSpacing: 0,
                crossAxisSpacing: 1.25,
                childAspectRatio: .85,
              ),
              itemCount: endIndex - startIndex,
              itemBuilder: (context, index) {
                final drinkId = drinkIds[startIndex + index];
                final drink = Provider.of<LocalDatabase>(context, listen: false)
                    .getDrinkById(drinkId.toString());

                return GestureDetector(
                  onTap: () {
                    final cart = Provider.of<Cart>(context, listen: false);
                    Navigator.of(context).push(_createRoute(drink, cart));
                  },
        
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CachedNetworkImage(
                                  imageUrl: drink.image,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned.fill(
                                child: Consumer<Cart>(
                                  builder: (context, cart, _) {
                                    int drinkQuantities =
                                        cart.getTotalQuantityForDrink(drink.id);

                                    if (drinkQuantities > 0) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'x$drinkQuantities',
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
                      Text(
                        drink.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
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

  Route _createRoute(Drink drink, Cart cart, {int targetPage = 0}) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => DrinkFeed(
        drink: drink,
        cart: cart,
        barId: widget.barId,
        initialPage: targetPage,
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
