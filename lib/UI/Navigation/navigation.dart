import 'package:megrim/UI/Navigation/cloud.dart';
import 'package:megrim/UI/HomePage/home.dart';
import 'package:megrim/UI/OrdersPage/orders.dart';
import 'package:megrim/UI/ProfilePage/profile.dart';
import 'package:megrim/UI/BankPage/bank.dart';
import 'package:flutter/material.dart';

class Navigation extends StatefulWidget {
  final int selectedTab;

  const Navigation({super.key, this.selectedTab = 0});

  @override
  NavigationState createState() => NavigationState();
}

class NavigationState extends State<Navigation> {
  late int _currentIndex;

  final List<Widget> _screens = [
    const HomePage(),
    const OrdersPage(),
    Container(color: Colors.black), // Placeholder for modal action
    const BankPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedTab;
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      showBottomSheet(context); // Trigger modal sheet for central button
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void showBottomSheet(
    BuildContext context,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20), // Customize the curve
        ),
      ),
      builder: (BuildContext context) {
        return const CloudPage();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey, // Border color
              width: .05, // Border width
            ),
          ),
        ),
        child: BottomAppBar(
          color: const Color.fromRGBO(0, 0, 0, 1),
          shape: const CircularNotchedRectangle(),
          notchMargin: 6.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left icons
              IconButton(
                icon: const Icon(Icons.home_rounded),
                color: _currentIndex == 0 ? Colors.white : Colors.grey,
                iconSize: 29,
                onPressed: () => _onTabTapped(0),
              ),
              IconButton(
                icon: const Icon(Icons.description),
                color: _currentIndex == 1 ? Colors.white : Colors.grey,
                iconSize: 24,
                onPressed: () => _onTabTapped(1),
              ),

              GestureDetector(
                onTap: () => showBottomSheet(context),
                child: Container(
                  height: 75,
                  width: 75,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        Colors.grey,
                        //Colors.white
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      height:
                          50, // Slightly smaller to create the border effect
                      width: 50,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black, // Black inner circle
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Colors.white,
                            //Colors.blue,
                            Colors.white
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Icon(
                          Icons.cloud,
                          size: 30,
                          color: Colors.white, // Acts as a fallback
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Right icons
              IconButton(
                icon: const Icon(Icons.attach_money),
                color: _currentIndex == 3 ? Colors.white : Colors.grey,
                iconSize: 29,
                onPressed: () => _onTabTapped(3),
              ),
              IconButton(
                icon: const Icon(Icons.person),
                color: _currentIndex == 4 ? Colors.white : Colors.grey,
                iconSize: 27,
                onPressed: () => _onTabTapped(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
