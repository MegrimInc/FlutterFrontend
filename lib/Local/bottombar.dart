import 'package:barzzy_app1/HomePage/home.dart';
import 'package:barzzy_app1/OrdersPage/orders.dart';
import 'package:barzzy_app1/OrdersPage/ordersv2-1.dart';
import 'package:barzzy_app1/ProfilePage/profile.dart';
import 'package:barzzy_app1/QrPage/qr.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';


class AuthPage extends StatefulWidget {
  final int selectedTab;
  const AuthPage({super.key, this.selectedTab = 0});

  @override
  AuthPageState createState() => AuthPageState();
}

class AuthPageState extends State<AuthPage> {
  late int _selectedIndex;
  late MobileScannerController _cameraController;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedTab;
    _cameraController = MobileScannerController(); 
    _initPages();
  }

  void _initPages() {
    _pages = [
      const HomePage(),
      const OrdersPage(bartenderID: '?',),
      QrPage(cameraController: _cameraController),
      const ProfilePage(),
    ];
  }

  @override
  void dispose() {
    _cameraController.dispose();
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
              icon: Icons.qr_code,
              iconSize: 23.7,
              text: 'QR',
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
