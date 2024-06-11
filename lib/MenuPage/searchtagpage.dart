import 'package:flutter/material.dart';
import '../Backend/bardatabase.dart';
import '../Backend/bar.dart';

class SearchTags extends StatefulWidget {
  final String barId;

  const SearchTags({
    super.key,
    required this.barId,
  });

  @override
  SearchTagsState createState() => SearchTagsState();
}

class SearchTagsState extends State<SearchTags> {
  Bar? currentBar;
  bool isLoading = true;
  Map<String, List<String>> nameAndTagMap = {};
  List<String> filteredDrinkIds = [];
  TextEditingController searchController = TextEditingController();

  FocusNode textFieldFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchBarData();
    _focusTextField(); // Focus the text field when the page is initialized
  }

  @override
  void dispose() {
    textFieldFocusNode.dispose(); // Dispose focus node
    super.dispose();
  }

  void _fetchBarData() async {
    currentBar = BarDatabase.getBarById(widget.barId);
    //nameAndTagMap = currentBar?.createNameAndTagMap() ?? {};
    setState(() {
      isLoading = false;
      nameAndTagMap = currentBar?.createNameAndTagMap() ?? {};
    });
  }

  void _focusTextField() {
    // Set a delay to ensure that the keyboard shows after the widget is fully built
    Future.delayed(Duration.zero, () {
      FocusScope.of(context).requestFocus(textFieldFocusNode);
    });
  }

  void _search(String query) {
    // Filter the drink IDs based on the search query
    List<String> filteredIds = [];
    query = query.toLowerCase().replaceAll(' ', ''); // Normalize query

    // Iterate through the name and tag map to find matches
    nameAndTagMap.forEach((key, value) {
      if (key.contains(query)) {
        filteredIds.addAll(value);
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
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Your other widgets here

                    // Add a focused text field
                    TextFormField(
                      controller: searchController,
                      focusNode: textFieldFocusNode,
                      onChanged: _search,
                      decoration: const InputDecoration(
                        labelText: 'Search',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    // Display filtered list of drinks
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredDrinkIds.length,
                        itemBuilder: (context, index) {
                          String drinkId = filteredDrinkIds[index];
                          // Retrieve the drink object using the ID and display it
                          // Replace this with your own implementation
                          return ListTile(
                            title: Text('Drink ID: $drinkId'),
                            // Implement onTap to navigate to drink details page or perform other actions
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
}
