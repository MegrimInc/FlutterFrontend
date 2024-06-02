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
  String appBarTitle = '';
  Widget actionWidget = const Icon(Icons.menu, color: Colors.white);
  bool isLoading = true;
  Bar? currentBar;
  List<String> displayedDrinkIds = [];
  bool isSecondLevelMenuOpen = false;
  String? previousCategory;
  GlobalKey _gridKey = GlobalKey();
   late Map<String, int> drinkCounts;

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
      displayedDrinkIds = currentBar!.drinks!.map((d) => d.id).toList();
      masterList = [widget.barId, ...displayedDrinkIds];
      drinkCounts = currentBar!.calculateDrinkCounts();
    }
    setState(() {
      isLoading = false;
      appBarTitle = currentBar!.name ?? 'Menu Page';
      actionWidget = const Icon(Icons.menu, 
      size: 28,
      color: Colors.white,
      );
      previousCategory = null;
      isSecondLevelMenuOpen = false;
      drinkCounts = currentBar!.calculateDrinkCounts();
    });

    await _handleBarTapAndReorder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.black,
        elevation: 0.0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, 
            color: Colors.white,
            size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(appBarTitle, 
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20
          )),
        actions: <Widget>[
          TextButton(
            onPressed: () => _togglePopupMenu(context),
            style: ButtonStyle(
              overlayColor: WidgetStateProperty.all(Colors.transparent),
            ),
            child: actionWidget,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchBarData,
              color: Colors.grey,
              backgroundColor: Colors.black,
              notificationPredicate: (_) => true,
              child: Padding(
                padding: const EdgeInsets.all(2.5),
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
                              padding: const EdgeInsets.only(top: 10.0,),
                              child: SizedBox(
                                //color: Colors.white,
                                width: 350,
                                child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                 
                                  children: [
                                
                                    // BAR PICTURE 
                                
                                    Column(
                                      children: [
                                        Container(
                                          width: 85,
                                          height: 85,
                                          margin:
                                              const EdgeInsets.symmetric(horizontal: 5),
                                          decoration: BoxDecoration(
                                            color: const Color.fromARGB(255, 0, 0, 0),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: .5,
                                            ),
                                            borderRadius: BorderRadius.circular(60),
                                          ),
                                          child: const Text(''),
                                        ),
                                      ],
                                    ),
                                
                                      //DRINK COUNT
                                
                                     SizedBox(
                                      width: 250,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          // Wrap each Text widget in a Column
                                          Column(
                                            children: [
                                              Text('${drinkCounts["Liquor"] ?? 0}'),
                                              const Text('Liquor'),
                                            ],
                                          ),
                                          Column(
                                            children: [
                                              Text('${drinkCounts["Casual"] ?? 0}'),
                                              const Text('Casual'),
                                            ],
                                          ),
                                          Column(
                                            children: [
                                              Text('${drinkCounts["Virgin"] ?? 0}'),
                                              const Text('Virgin'),
                                            ],
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        final drink = currentBar!.drinks!
                            .firstWhere((d) => d.id == masterList[index]);

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
                                            MainAxisAlignment.spaceBetween,
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
    );
  }

  void _togglePopupMenu(BuildContext context) async {
    if (previousCategory == null) {
      _showPrimaryPopupMenu(context);
    } else {
      _showSubmenu(context, previousCategory!);
    }
  }

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
      displayedDrinkIds = currentBar!.drinks!
          .where((drink) => drink.type.trim() == selected.trim())
          .map((d) => d.id)
          .toList();
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
      displayedDrinkIds = currentBar!.drinks!
          .where((drink) => drink.ingredients.contains(selected))
          .map((d) => d.id)
          .toList();

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
