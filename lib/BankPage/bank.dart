import 'package:barzzy/MenuPage/menu.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:barzzy/Backend/localdatabase.dart';

class BankPage extends StatefulWidget {
  const BankPage({super.key});

  @override
  State<BankPage> createState() => _BankPageState();
}

class _BankPageState extends State<BankPage>  {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    // Listen for focus changes
    _focusNode.addListener(() {
      setState(() {}); // Triggers rebuild on focus change
    });
  }


  @override
  Widget build(BuildContext context) {

    final localDatabase = Provider.of<LocalDatabase>(context, listen: false);

    final filteredBars = localDatabase.getSearchableBarInfo().entries.where(
      (entry) {
        final name = entry.value['name'] ?? '';
        return name.toLowerCase().contains(_searchText.toLowerCase());
      },
    ).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 35),
            _buildSearchBar(),
            const SizedBox(height: 35),
            Expanded(
              child: ListView.separated(
                itemCount: filteredBars.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final barId = filteredBars[index].key;
                  final barName =
                      filteredBars[index].value['name'] ?? 'Unknown';
                  final points =
                      localDatabase.getPointsForBar(barId)?.points ?? 0;
                  final tagImage = LocalDatabase.getBarById(barId)?.tagimg ??
                      'https://www.barzzy.site/images/default.png';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MenuPage(barId: barId),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.transparent,
                          backgroundImage: CachedNetworkImageProvider(tagImage),
                        ),
                        title: Text(
                          '$barName - $points pts',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 65,
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 0, 0, 0),
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.0415),
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        style: const TextStyle(color: Colors.white),
        cursorColor: Colors.white,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          filled: true,
          border: InputBorder.none,
          fillColor: const Color.fromARGB(255, 0, 0, 0),
          hintText: _focusNode.hasFocus ? '' : 'Search... e.g. The Burg',
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
        onChanged: (text) {
          setState(() {
            _searchText = text;
          });
        },
        keyboardAppearance: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
