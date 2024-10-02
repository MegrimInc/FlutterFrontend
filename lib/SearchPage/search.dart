import 'package:barzzy/Backend/searchengine.dart';
import 'package:barzzy/SearchPage/searchbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barzzy/MenuPage/menu.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  Map<String, Map<String, String>> _filteredBars = {};
  final FocusNode _focusNode = FocusNode();

  void _handleSearchChanged(String searchText) {
    final searchService = Provider.of<SearchService>(context, listen: false);
    Map<String, Map<String, String>> filteredBars =
        searchService.searchBars(searchText);

    setState(() {
      _filteredBars = filteredBars;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Search(
              onSearchChanged: _handleSearchChanged,
              focusNode: _focusNode,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredBars.length,
                itemBuilder: (context, index) {
                  String barId = _filteredBars.keys.elementAt(index);
                  Map<String, String> barInfo = _filteredBars[barId]!;
                  String displayText =
                      "${barInfo['name']} - ${barInfo['address']}";
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    tileColor: Colors.transparent,
                    leading:
                        const Icon(Icons.chevron_right, color: Colors.white),
                    title: Text(
                      displayText,
                      style: GoogleFonts.sourceSans3(color: Colors.grey),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            // ignore: prefer_const_constructors
                            builder: (context) => MenuPage(barId: barId)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
}
