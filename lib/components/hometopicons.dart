import 'package:barzzy_app1/search.dart';
import 'package:barzzy_app1/tabs.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/heroicons_solid.dart';



class MyTopIcons extends StatefulWidget {
  
  const MyTopIcons({super.key});

  @override
  State<MyTopIcons> createState() => _MyTopIconsState();
}

class _MyTopIconsState extends State<MyTopIcons> {
  // late TextEditingController _searchController;

  // @override
  // void initState() {
  //   super.initState();
  //   _searchController = TextEditingController();
  // }

  // @override
  // void dispose() {
  //   _searchController.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 57.5, 15, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          //BARZZY TAG

          Container(
            padding: const EdgeInsets.only(left: 15.97445, top: 7),
            width: (MediaQuery.of(context).size.width / 3) * 2 + 1,
            height: 45,
            child: Text(
              'B A R Z Z Y',
              style: GoogleFonts.megrim(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),

          //SEARCH

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchPage(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Iconify(
                
                HeroiconsSolid.search,
                size: 3,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 10),

          //TAB BUTTON
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TabsPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Iconify(
                HeroiconsSolid.clipboard_list,
                size: 5,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
