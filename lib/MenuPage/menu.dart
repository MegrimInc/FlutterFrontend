import 'package:barzzy_app1/Backend/barhistory.dart';
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
  Widget actionWidget = const Icon(Icons.menu, color: Colors.white);
  bool isLoading = true;
  Bar? currentBar;
  // DRINK COUNT AND DISPLAY DRINK IDS
  List<String> displayedDrinkIds = [];
  Map<String, int> drinkCounts = {};
  GlobalKey _gridKey = GlobalKey();

  Future<void> _focusTextField() async {
  appBarController.text = '';
  _isFocused = true;
  _focusNode.requestFocus();
  _focusNode.addListener(() {
    if (!_focusNode.hasFocus && _isFocused) {
      // If the user has typed nothing after "All&"
      if (appBarController.text == '& ') {
        setState(() {
          // Reset to currentBar.tag if user types nothing
          appBarController.text =
              '@${(currentBar!.tag ?? 'Menu Page').replaceAll(' ', '').toLowerCase()}';
        });
      }
      _isFocused = false;
    }
  });
}

  TextEditingController appBarController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
void initState() {
  super.initState();
  _fetchBarData();

  _focusNode.addListener(() {
    if (_focusNode.hasFocus && !_isFocused) {
      setState(() {
        _isFocused = true;
        // If the text field is empty, set the prefix "All&"
        if (appBarController.text.isEmpty) {
          appBarController.text = '';
        }
      });
    }
  });
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
      // appBarTitle =
      //     '@${(currentBar!.tag ?? 'Menu Page').replaceAll(' ', '').toLowerCase()}';
      appBarController.text =
          '@${(currentBar!.tag ?? 'Menu Page').replaceAll(' ', '').toLowerCase()}';
      actionWidget = const Icon(
        Icons.menu,
        size: 26,
        color: Colors.white,
      );
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
                          padding: const EdgeInsets.only(left: 7.5),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 27,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        Center(
                          child: SizedBox(
                            width: 250,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 7.5),
                              child: TextField(
                                controller: appBarController,
                                focusNode: _focusNode,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  //prefixText: 'All&',
                                  hintText: appBarController.text,
                                  border: InputBorder.none,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                                onTap: () {
                                  if (!_isFocused) {
                                    setState(() {
                                      _isFocused = true;
                                      //appBarController.clear();
                                    });
                                  }
                                },
                                onChanged: (text) {
    if (!text.startsWith('')) {
      setState(() {
        appBarController.text = '';
      });
    }
  },
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _focusTextField,
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
                      onRefresh: _focusTextField,
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
                                          top: 8.0, right: 10),
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
                                                onTap: () async {
                                                  const String selected =
                                                      'Liquor'; // Assuming 'Liquor' is selected
                                                  if (currentBar?.drinks !=
                                                      null) {
                                                    displayedDrinkIds = currentBar!
                                                        .getDrinkIdsByCategory(
                                                            selected);
                                                    masterList = [
                                                      widget.barId,
                                                      ...displayedDrinkIds
                                                    ];
                                                    setState(() {
                                                      _gridKey = GlobalKey();
                                                      appBarController.text =
                                                          selected;
                                                    });
                                                  }
                                                },
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      '${drinkCounts["Liquor"] ?? 0}',
                                                      style: const TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                    const Text('Liquor',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white)),
                                                  ],
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () async {
                                                  const String selected =
                                                      'Brew'; // Assuming 'Liquor' is selected
                                                  if (currentBar?.drinks !=
                                                      null) {
                                                    displayedDrinkIds = currentBar!
                                                        .getDrinkIdsByCategory(
                                                            selected);
                                                    masterList = [
                                                      widget.barId,
                                                      ...displayedDrinkIds
                                                    ];
                                                    setState(() {
                                                      _gridKey = GlobalKey();
                                                      appBarController.text =
                                                          selected;
                                                    });
                                                  }
                                                },
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      '${drinkCounts["Brew"] ?? 0}',
                                                      style: const TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                    const Text('Brew',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white)),
                                                  ],
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () async {
                                                  const String selected =
                                                      'Virgin';
                                                  if (currentBar?.drinks !=
                                                      null) {
                                                    displayedDrinkIds = currentBar!
                                                        .getDrinkIdsByCategory(
                                                            selected);
                                                    masterList = [
                                                      widget.barId,
                                                      ...displayedDrinkIds
                                                    ];
                                                    setState(() {
                                                      _gridKey = GlobalKey();
                                                      appBarController.text =
                                                          selected;
                                                    });
                                                  }
                                                },
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      '${drinkCounts["Virgin"] ?? 0}',
                                                      style: const TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                    const Text('Virgin',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white)),
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
        // const QuiltedGridTile(1, 1),
        // const QuiltedGridTile(1, 1),
        // const QuiltedGridTile(1, 1),
      ]);
    }
    return pattern;
  }
}
