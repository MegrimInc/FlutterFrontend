import 'package:barzzy_app1/SettingsPage/settings.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/heroicons_solid.dart';
 

class MyTopIcons1 extends StatefulWidget {
   const MyTopIcons1({super.key});

  @override
  State<MyTopIcons1> createState() => _MyTopIcons1State();
}

class _MyTopIcons1State extends State<MyTopIcons1> {
  @override
  Widget build(BuildContext context) {
    return Container(
    padding: const EdgeInsets.fromLTRB(15, 57.5, 15, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [ 

          //BARZZY TAG

           Container(
                padding: const EdgeInsets.only(left: 15.5, top: 19
                ),
                width: (MediaQuery.of(context).size.width / 3) * 2 + 1,
                height: 45,
                child: Text(
                  'Barzzy',
                  style: GoogleFonts.lakkiReddy(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize:25,
                  ),
                ),
              ),
          


          //SETTINGS BUTTON
          
          GestureDetector(
            onTap: () {
              // Navigate to FriendsPage() when the icon is tapped
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            child: Container( 
              padding: const EdgeInsets.all(10),
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 4, 7, 9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Iconify(
                HeroiconsSolid.cog,
                size: 5,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 10),

          //CART BUTTON 
          GestureDetector(
            onTap: () {
              // Navigate to FriendsPage() when the icon is tapped
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 4, 7, 9),
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