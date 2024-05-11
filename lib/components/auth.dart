// ignore: unused_import
import 'package:barzzy_app1/home.dart';
import 'package:barzzy_app1/notifications.dart';
import 'package:barzzy_app1/orders.dart';
import 'package:barzzy_app1/profile.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:google_fonts/google_fonts.dart';



class AuthPage extends StatefulWidget {
  const AuthPage({super.key,});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late int _selectedIndex;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
    _initPages();
  }

  void _initPages() {
    _pages = [
      const HomePage(),
      //const HomePage(),
      const OrdersPage(),
      const ProfilePage(),
      const NotificationsPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // User is logged in, display the main content
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        //Color(0xFF1A1819),
        border: Border(
            top: BorderSide(
                color: Color.fromARGB(255, 126, 126, 126), width: .075)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: GNav(
          backgroundColor: Colors.black,
          //Color(0xFF1A1819),
          gap: 7.65,
          color: Colors.grey,
          activeColor: Colors.grey,
          padding: const EdgeInsets.fromLTRB(20, 13, 20, 31),
          selectedIndex: _selectedIndex,
          onTabChange: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          tabs: [
            GButton(
              //icon: Icons.home,
              icon: Icons.home_rounded,
              iconSize: 26.55,
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
              iconSize: 22.15,
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
              icon: Icons.person,
              iconSize: 24.88,
              text: 'Me',
              iconActiveColor: Colors.white,
              textStyle: GoogleFonts.sourceSans3(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _selectedIndex == 2
                      ? const Color.fromARGB(255, 255, 255, 255)
                      : Colors.grey),
            ),
            GButton(
              icon: Icons.notifications_active,
              iconSize: 22.15,
              text: 'Notifications',
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