import 'package:barzzy/SearchPage/search.dart';
import 'package:barzzy/TabsPage/tabs.dart';
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
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 49.5, 12, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          //BARZZY TAG

          Container(
            padding: const EdgeInsets.only(top: 5.5),
            width: (MediaQuery.of(context).size.width / 3) * 2 + 0,
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

          const SizedBox(width: 20),

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
            child: const SizedBox(
              width: 40,
              child: Iconify(
                HeroiconsSolid.search,
                size: 24,
                color: Colors.grey,
              ),
            ),
          ),

          //const SizedBox(width: 15),

          // //TAB BUTTON
          // GestureDetector(
          //   onTap: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => const TabsPage()),
          //     );
          //   },
          //   child: const Iconify(
          //     HeroiconsSolid.clipboard_list,
          //     size: 24.9,
          //     color: Colors.grey,
          //   ),
          // ),
        ],
      ),
    );
  }
}
