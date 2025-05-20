import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/heroicons_solid.dart';

class Search extends StatefulWidget {
  final Function(String) onSearchChanged;
  final FocusNode focusNode;

  const Search({super.key, required this.onSearchChanged, required this.focusNode});

  @override
  SearchState createState() => SearchState();
}

class SearchState extends State<Search> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      widget.onSearchChanged(_searchController.text);
    });
    // Request focus when the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15),
      child: Container(
        height: 69.3,
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 0, 0, 0),
          border: Border(
            bottom: BorderSide(color: Colors.grey, width: 0.0415),
          ),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 20, right: 0),
              child: Iconify(
                HeroiconsSolid.search,
                color: Colors.white,
                size: 22,
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
              height: 50,
              width: MediaQuery.of(context).size.width - 145,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
              child: TextField(
                focusNode: widget.focusNode,
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  filled: true,
                  hintText: 'Find your merchant...',
                  contentPadding: const EdgeInsets.fromLTRB(10, -5, 20, 12),
                  hintStyle: GoogleFonts.sourceSans3(color: Colors.grey),
                  border: InputBorder.none,
                  fillColor: const Color.fromARGB(255, 0, 0, 0),
                ),
                keyboardAppearance: Brightness.light
              ),
            ),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.sourceSans3(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    fontSize: 17.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}