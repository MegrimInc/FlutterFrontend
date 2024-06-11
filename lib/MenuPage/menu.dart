import 'package:barzzy_app1/Backend/barhistory.dart';
import 'package:barzzy_app1/Backend/user.dart';
import 'package:barzzy_app1/MenuPage/searchtagpage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/heroicons_solid.dart';
import 'package:provider/provider.dart';
import '../Backend/bar.dart';
import '../Backend/bardatabase.dart';

class MenuPage extends StatefulWidget {
  final String barId;

  const MenuPage({
    super.key,
    required this.barId,
  });

  @override
  MenuPageState createState() => MenuPageState();
}

class MenuPageState extends State<MenuPage> {
  String appBarTitle = '';
  List<String> filteredDrinkIds = [];
  List<String> masterList = [];
  bool isLoading = true;
  Bar? currentBar;
  List<String> displayedDrinkIds = [];
  Map<String, int> drinkCounts = {};
  Map<String, List<String>> nameAndTagMap = {};
  final GlobalKey _gridKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  

  @override
  void initState() {
    super.initState();
    _fetchBarData();
  }

  //SENDS ID TO BAR HISTORY CLASS

  Future<void> _handleBarTapAndReorder() async {
    await Future.delayed(Duration.zero);
    // ignore: use_build_context_synchronously
    final barHistory = Provider.of<BarHistory>(context, listen: false);
    // ignore: use_build_context_synchronously
    barHistory.tapBar(widget.barId, context);

    barHistory.reorderList(widget.barId);
  }

  //LOADS DRINK IN

  Future<void> _fetchBarData() async {
    currentBar = BarDatabase.getBarById(widget.barId);
    if (currentBar != null) {
      displayedDrinkIds = currentBar!.getAllDrinkIds();
      masterList = [widget.barId, ...displayedDrinkIds];
      drinkCounts = currentBar!.getDrinkCounts();
      (currentBar!.tag ?? 'Menu Page').replaceAll(' ', '').toLowerCase();
    }

    setState(() {
      isLoading = false;
      appBarTitle =
          (currentBar!.tag ?? 'Menu Page').replaceAll(' ', '').toLowerCase();
      nameAndTagMap = currentBar?.createNameAndTagMap() ?? {};
    });

    await _handleBarTapAndReorder();
  }

  void _search(String query) {
    // Filter the drink IDs based on the search query
    List<String> filteredIds = [];
    query = query.toLowerCase().replaceAll(' ', ''); // Normalize query
    

    // Iterate through the name and tag map to find matches
    nameAndTagMap.forEach((key, value) {
      if (key.contains(query)) {
        filteredIds.addAll(value);
        masterList = [widget.barId, ...filteredIds];
        
      }
    });

    setState(() {
      filteredDrinkIds = filteredIds;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          backgroundColor: Colors.black,
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(children: [
                  //CUSTOM APP BAR

                  Column(
                    children: [
                      SizedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            //BACK ARROW BUTTON

                            Padding(
                              padding: const EdgeInsets.only(left: 11),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),

                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 5),
                                child: Text(
                                  appBarTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),

                            // SEARCH BUTTON AND DRINK COUNT

                            GestureDetector(
                              child: const Row(
                                children: [
                                  //SEARCH BUTTON

                                  Iconify(
                                    HeroiconsSolid.search,
                                    size: 24,
                                    color: Colors.grey,
                                  ),

                                  //DRINK COUNT

                                  Text('1.6k')
                                ],
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SearchTags(barId: widget.barId),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
  decoration: const BoxDecoration(
    border: Border(
      bottom: BorderSide(
        color: Color.fromARGB(255, 126, 126, 126),
        width: 0.1,
      ),
    ),
  ),
  height: 50,
  child: Consumer<User>(
    builder: (context, user, child) {
      List<String> searchHistory = user.getSearchHistory();
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: user.searchHistory.length,
        itemBuilder: (context, index) {
          // Here you can customize the appearance of each item in the list
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
           child: Text(
          searchHistory[index],
          style: const TextStyle(
            color: Colors.white, // Adjust text color as needed
            fontSize: 16, // Adjust font size as needed
          ),
        ),
          );
        },
      );
    },
  ),
),

                    ],
                  ),

                  //HEADER AND DRINK LIST AND BELOW

                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _fetchBarData,
                      color: Colors.grey,
                      backgroundColor: Colors.black,
                      notificationPredicate: (_) => true,
                      child: Padding(
                        padding: const EdgeInsets.all(1),
                        child: GridView.custom(
                          key: _gridKey,
                          gridDelegate: SliverQuiltedGridDelegate(
                            crossAxisCount: 3,
                            mainAxisSpacing: 2.5,
                            crossAxisSpacing: 2.5,
                            pattern: _generatePattern(masterList.length),
                          ),
                          childrenDelegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == 0) {
                                // HEADER

                                return const Column(
                                  children: [
                                    Padding(
                                      padding:
                                          EdgeInsets.only(top: 8.0, right: 10),
                                      child: SizedBox(
                                        width: 360,
                                        child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              // Container(
                                              //   width: 85,
                                              //   height: 85,
                                              //   margin:
                                              //       const EdgeInsets.symmetric(
                                              //           horizontal: 5),
                                              //   decoration: BoxDecoration(
                                              //     color: const Color.fromARGB(
                                              //         255, 0, 0, 0),
                                              //     border: Border.all(
                                              //       color: Colors.white,
                                              //       width: .5,
                                              //     ),
                                              //     borderRadius:
                                              //         BorderRadius.circular(60),
                                              //   ),
                                              //   child: const Text(''),
                                              // ),

                                              // Text(
                                              //   "$appBarTitle's Menu",
                                              //   style: const TextStyle(
                                              //     color: Colors.white,
                                              //     fontSize: 20,
                                              //   ),
                                              // ),
                                              Center(
                                                child: Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 20),
                                                  child: Text(
                                                      '`Vodka `Manhattan `Liquor',
                                                      style: TextStyle(
                                                          fontSize: 25,
                                                          color: Colors.white)),
                                                ),
                                              )
                                            ]),
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                final drink = currentBar!.drinks!.firstWhere(
                                    (d) => d.id == masterList[index]);

                                // DRINK FEED

                                return ClipRRect(
                                  borderRadius: const BorderRadius.vertical(),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: Image.asset(
                                          drink.image,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 10,
                                        left: 10,
                                        right: 10,
                                        child: Container(
                                          color: Colors.black.withOpacity(0.5),
                                          padding: const EdgeInsets.all(5),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                drink.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    '\$${drink.price.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${drink.alcohol}%',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                drink.description,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            childCount: masterList.length,
                          ),
                        ),
                      ),
                    ),
                  ),

                  BottomAppBar(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            // child: TextField(
                            //   decoration: InputDecoration(
                            //     hintText: 'Type a message...',
                            //   ),
                            // ),
                            child: TextFormField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                labelText: 'Search',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () {
                              String query = _searchController.text;
                              print('Query being sent: $query');
                              Provider.of<User>(context, listen: false)
                                  .addSearchQuery(query);
                              _search(query);
                              _searchController.clear();
                              FocusScope.of(context).unfocus();
                              // Send message functionality
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ])),
    );
  }

  // PATTERN METHOD

  List<QuiltedGridTile> _generatePattern(int length) {
    List<QuiltedGridTile> pattern = [];
    pattern.add(
        const QuiltedGridTile(1, 3)); // Add the initial pattern for index 0
    for (int i = 1; i < length; i++) {
      pattern.addAll([
        const QuiltedGridTile(2, 1),
        const QuiltedGridTile(2, 1),
        const QuiltedGridTile(2, 1),
      ]);
    }
    return pattern;
  }
}
