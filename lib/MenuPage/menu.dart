import 'package:barzzy_app1/Backend/barhistory.dart';
import 'package:barzzy_app1/MenuPage/contextmenu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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
  List<String> masterList = [];
  String appBarTitle = '';
  Widget actionWidget = const Icon(Icons.menu, color: Colors.white);
  bool isLoading = true;
  Bar? currentBar;

  // DRINK COUNT AND DISPLAY DRINK IDS
  List<String> displayedDrinkIds = [];
  Map<String, int> drinkCounts = {};

  bool isSecondLevelMenuOpen = false;
  String? previousCategory;
  GlobalKey _gridKey = GlobalKey();

  final Map<String, List<String>> secondLevelOptions = {
    'Liquor': ['Vodka', 'Whiskey', 'Rum', 'Gin', 'Tequila', 'Brandy'],
    'Casual': ['Beer', 'Seltzer'],
    'Virgin': [],
  };

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
    }

    setState(() {
      isLoading = false;
      appBarTitle = currentBar!.tag ?? 'Menu Page';
      actionWidget = const Icon(
        Icons.menu,
        size: 26,
        color: Colors.white,
      );
      previousCategory = null;
      isSecondLevelMenuOpen = false;
    });

    await _handleBarTapAndReorder();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          backgroundColor: Colors.black,
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(children: [
                  SizedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                            padding: const EdgeInsets.only(left: 11),
                            child: Text(
                              appBarTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _togglePopupMenu(context),
                          style: ButtonStyle(
                            overlayColor:
                                WidgetStateProperty.all(Colors.transparent),
                          ),
                          child: actionWidget,
                        ),
                      ],
                    ),
                  ),
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

                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 8.0, right: 11),
                                      child: SizedBox(
                                        width: 360,
                                        child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Container(
                                                width: 85,
                                                height: 85,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 5),
                                                decoration: BoxDecoration(
                                                  color: const Color.fromARGB(
                                                      255, 0, 0, 0),
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: .5,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(60),
                                                ),
                                                child: const Text(''),
                                              ),

                                              //DRINK COUNT

                                              GestureDetector(
                                                onTap: () {
                                                  _showContextMenu(
                                                      'Liquor', context);
                                                },
                                                child: Column(
                                                  children: [
                                                    Text(
                                                        '${drinkCounts["Liquor"] ?? 0}'),
                                                    const Text('Liquor'),
                                                  ],
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  _showContextMenu(
                                                      'Casual', context);
                                                },
                                                child: Column(
                                                  children: [
                                                    Text(
                                                        '${drinkCounts["Casual"] ?? 0}'),
                                                    const Text('Casual'),
                                                  ],
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  _showContextMenu(
                                                      'Virgin', context);
                                                },
                                                child: Column(
                                                  children: [
                                                    Text(
                                                        '${drinkCounts["Virgin"] ?? 0}'),
                                                    const Text('Virgin'),
                                                  ],
                                                ),
                                              ),
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

  //MAIN FILTER MENU

  Future<void> _showPrimaryPopupMenu(BuildContext context) async {
    final String? selected = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 80, 0, 0),
      initialValue: null,
      items: <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(value: 'Liquor', child: Text('Liquor')),
        const PopupMenuItem<String>(value: 'Casual', child: Text('Casual')),
        const PopupMenuItem<String>(value: 'Virgin', child: Text('Virgin')),
      ],
      elevation: 8.0,
    );

    if (selected != null && currentBar?.drinks != null) {
      displayedDrinkIds = currentBar!.getDrinkIdsByCategory(selected);
      masterList = [widget.barId, ...displayedDrinkIds];

      setState(() {
        _gridKey = GlobalKey();
        appBarTitle = selected;
        actionWidget =
            const Text('Filter', style: TextStyle(color: Colors.white));
        previousCategory = selected;
      });
    }
  }

  // SUB FILTER MENU

  Future<void> _showSubmenu(BuildContext context, String category) async {
    final String? selected = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 80, 0, 0),
      items: secondLevelOptions[category]!
          .map((option) =>
              PopupMenuItem<String>(value: option, child: Text(option)))
          .toList(),
      elevation: 8.0,
    );

    if (selected != null && currentBar?.drinks != null) {
      displayedDrinkIds =
          currentBar!.getDrinkIdsBySubcategory(category, selected);
      masterList = [widget.barId, ...displayedDrinkIds];

      setState(() {
        _gridKey = GlobalKey();
        appBarTitle = selected; // Set the AppBar title to the selected sub-type
        actionWidget =
            const Text('Filter', style: TextStyle(color: Colors.white));
        previousCategory = category; // Set the previous category for toggling
      });
    }
  }

  //TOGGLE MENU METHOD

  void _togglePopupMenu(BuildContext context) async {
    if (previousCategory == null) {
      _showPrimaryPopupMenu(context);
    } else {
      _showSubmenu(context, previousCategory!);
    }
  }
}

void _showContextMenu(String category, BuildContext context) {
  showCupertinoModalPopup(
    context: context,
    builder: (BuildContext context) {
      return ContextMenu(category: category);
    },
  );
}
