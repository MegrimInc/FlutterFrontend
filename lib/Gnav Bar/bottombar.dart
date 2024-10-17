import 'package:barzzy/HomePage/home.dart';
import 'package:barzzy/OrdersPage/pickuppage.dart';
import 'package:barzzy/ProfilePage/profile.dart';
import 'package:barzzy/BankPage/bank.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthPage extends StatefulWidget {
  final int selectedTab;
  const AuthPage({super.key, this.selectedTab = 0});

  @override
  AuthPageState createState() => AuthPageState();
}

class AuthPageState extends State<AuthPage> {
  late int _selectedIndex;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedTab;

    _initPages();
  }

  void _initPages() {
    _pages = [
      const HomePage(),
      const PickupPage(),
      //const BankPage(),
       BankPage(key: UniqueKey()),
      const ProfilePage(),
    ];
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
            top: BorderSide(
                color: Color.fromARGB(255, 126, 126, 126), width: .08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 3),
        child: GNav(
          backgroundColor: Colors.black,
          gap: 7.65,
          color: Colors.grey,
          activeColor: Colors.grey,
          padding: const EdgeInsets.fromLTRB(20, 13, 20, 31),
          selectedIndex: _selectedIndex,
          onTabChange: (index) {
            setState(() {
              _selectedIndex = index;
               if (index == 2) {
                // Force BankPage to rebuild by assigning a new key
                _pages[2] = BankPage(key: UniqueKey());
              }
            });
          },
          tabs: [
            GButton(
              icon: Icons.home_rounded,
              iconSize: 25.75,
              text: 'Home',
              iconActiveColor: Colors.white,
              textStyle: GoogleFonts.sourceSans3(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _selectedIndex == 0
                    ? const Color.fromARGB(255, 255, 255, 255)
                    : Colors.grey,
              ),
            ),
            GButton(
              icon: Icons.description,
              iconSize: 22,
              text: 'Orders',
              iconActiveColor: Colors.white,
              textStyle: GoogleFonts.sourceSans3(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _selectedIndex == 1
                    ? const Color.fromARGB(255, 255, 255, 255)
                    : Colors.grey,
              ),
            ),
            GButton(
              icon: Icons.attach_money,
              iconSize: 26,
              text: 'Bank',
              iconActiveColor: Colors.white,
              textStyle: GoogleFonts.sourceSans3(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _selectedIndex == 2
                      ? const Color.fromARGB(255, 255, 255, 255)
                      : Colors.grey),
            ),
            GButton(
              icon: Icons.person,
              iconSize: 25.88,
              text: 'Me',
              iconActiveColor: Colors.white,
              textStyle: GoogleFonts.sourceSans3(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _selectedIndex == 3
                      ? const Color.fromARGB(255, 255, 255, 255)
                      : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
