import 'package:barzzy_app1/components/barhistory.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'backend/bar.dart';
import 'backend/bardatabase.dart';

class MenuPage extends StatefulWidget {
  final String barId; // Assume barId is passed to this page

  const MenuPage({super.key, required this.barId});

  @override
  MenuPageState createState() => MenuPageState();
}

class MenuPageState extends State<MenuPage> {
  String appBarTitle = '';
  Widget actionWidget = const Icon(Icons.menu, color: Colors.white);
  bool isLoading = true;
  Bar? currentBar;
  List<String> displayedDrinkIds = []; // List of currently displayed drink IDs

  final Map<String, List<String>> secondLevelOptions = {
    'Liquor': ['Vodka', 'Whiskey', 'Rum', 'Gin', 'Tequila', 'Brandy'],
    'Casual': ['Beer', 'Seltzer'],
    'Virgin': [],
  };

  bool isSecondLevelMenuOpen = false;
  String? previousCategory;

  @override
  void initState() {
    super.initState();
    _fetchBarData();
  }

  Future<void> _fetchBarData() async {
    final barDatabase = Provider.of<BarDatabase>(context, listen: false);
    currentBar = barDatabase.getBarById(widget.barId);
    if (currentBar != null) {
        displayedDrinkIds = currentBar!.drinks!.map((d) => d.id).toList(); // Use IDs to manage displayed drinks
        debugPrint("Reloaded ${displayedDrinkIds.length} drinks from the bar.");
        WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<BarHistory>(context, listen: false).addToHistory(widget.barId);
      });
    }
    setState(() {
        isLoading = false;
        appBarTitle = currentBar!.name ?? 'Menu Page';
        actionWidget = const Icon(Icons.menu, color: Colors.white);
        previousCategory = null;
        isSecondLevelMenuOpen = false;
    });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.black,
        elevation: 0.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(appBarTitle, style: const TextStyle(color: Colors.white)),
        actions: <Widget>[
          TextButton(
            onPressed: () => _togglePopupMenu(context),
            style: ButtonStyle(
              overlayColor: MaterialStateProperty.all(Colors.transparent),
            ),
            child: actionWidget,
          ),
        ],
      ),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _fetchBarData,
        color: Colors.grey,
        backgroundColor: Colors.black,
        notificationPredicate: (_) => true,
        child: ListView.builder(
          itemCount: displayedDrinkIds.length,
          itemBuilder: (context, index) {
            final drink = currentBar!.drinks!.firstWhere((d) => d.id == displayedDrinkIds[index]);
            return ListTile(
              title: Text(drink.name, style: const TextStyle(color: Colors.white)),
            );
          },
        ),
      ),
    );
  }

  void _togglePopupMenu(BuildContext context) async {
    // If no category has been selected yet, show the primary menu
    if (previousCategory == null) {
      _showPrimaryPopupMenu(context);
    } else {
      // If a primary category is already selected, show the submenu for that category
      _showSubmenu(context, previousCategory!);
    }
  }

  Future<void> _showPrimaryPopupMenu(BuildContext context) async {
    final String? selected = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 80, 0, 0),
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
      setState(() {
        appBarTitle = selected; // Set the AppBar title to the selected type
        actionWidget = const Text('Filter', style: TextStyle(color: Colors.white));
        previousCategory = selected;
        isSecondLevelMenuOpen = true; // Now the second-level menu is open
      });
    }
  }

  Future<void> _showSubmenu(BuildContext context, String category) async {
    final List<String> secondOptions = secondLevelOptions[category] ?? [];
    final String? selected = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(200, 80, 0, 0),
      items: secondOptions.map((option) {
        return PopupMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      elevation: 8.0,
    );
    if (selected != null) {
      displayedDrinkIds = currentBar!.drinks!
        .where((drink) => drink.ingredients.contains(selected))
        .map((d) => d.id)
        .toList();
      setState(() {
        actionWidget = Text(selected, style: const TextStyle(color: Colors.white));
        isSecondLevelMenuOpen = false; // Close the second-level menu after selection
      });
    }
  }
}
