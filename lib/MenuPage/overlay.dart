// import 'dart:ui';
// import 'package:barzzy_app1/Backend/localdatabase.dart';
// import 'package:barzzy_app1/MenuPage/cart.dart';
// import 'package:flutter/material.dart';
// import 'package:iconify_flutter/iconify_flutter.dart';
// import 'package:iconify_flutter/icons/heroicons_solid.dart';
// import 'package:provider/provider.dart';
// import 'package:barzzy_app1/Backend/user.dart';

// class HistorySheet extends StatefulWidget {
//   final String barId;
//   final VoidCallback onClose;
//   final Cart cart;

//   const HistorySheet({
//     super.key,
//     required this.barId,
//     required this.onClose,
//     required this.cart,
//   });

//   @override
//   HistorySheetState createState() => HistorySheetState();
// }

// class HistorySheetState extends State<HistorySheet>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _fadeAnimation;
//   final PageController _pageController = PageController();
//   static const int itemsPerPage = 7; // Number of items per page
//   int currentPage = 0;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 250),
//     );
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeIn),
//     );

//     // Start the animation with a slight delay
//     Future.delayed(const Duration(milliseconds: 100), () {
//       _controller.forward();
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _pageController.dispose();
//     super.dispose();
//   }

//   void _closeSheet() {
//     _controller.reverse().then((_) {
//       Future.delayed(const Duration(milliseconds: 0), widget.onClose);
//     });
//   }

 
//   void _searchDrink(String query) {
//     final normalizedQuery = query
//         .toLowerCase()
//         .trim()
//         .replaceAll(RegExp(r'[^a-z0-9_]', caseSensitive: false), '');
//   // Close the sheet immediately
//   _closeSheet();
  
//   // Delay the search operation by 500 milliseconds
//   Future.delayed(const Duration(milliseconds: 250), () {
//     final user = Provider.of<User>(context, listen: false);
//     final barDatabase = Provider.of<LocalDatabase>(context, listen: false);
//     barDatabase.searchDrinks(normalizedQuery, user, widget.barId);
//   });
// }

//   @override
// Widget build(BuildContext context) {
//   final barDatabase = Provider.of<LocalDatabase>(context, listen: false);
//   final user = Provider.of<User>(context);
//   final lastSearch = user.getLastSearch(widget.barId);
//   final drinkNames = lastSearch?.value.map((id) {
//   final drink = barDatabase.getDrinkById(id);
//   return drink.name;
// }).toList() ?? [];

//   // Calculate the number of pages
//   final int pageCount = (drinkNames.length / itemsPerPage).ceil();

//   return Scaffold(
//     backgroundColor: Colors.transparent,
//     //backgroundColor: Colors.black.withOpacity(0.5),
//     body: GestureDetector(
//       onTap: _closeSheet,
//       child: Stack(
//         children: [
//           // Blurred background
//           BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
//             child: Container(
//               color: Colors.transparent,
//             ),
//           ),


//          Positioned(
//               top: 20, // Distance from the top of the screen
//               right: 20, // Distance from the right side of the screen
//               child: FadeTransition(
//                 opacity: _fadeAnimation,
//                 child: drinkNames.isEmpty
//                     ? const Text(
//                         '0 of 0',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 21,
//                           fontStyle: FontStyle.italic,
//                         ),
//                       )
//                     : AnimatedBuilder(
//                         animation: _pageController,
//                         builder: (context, child) {
//                           final currentPage = _pageController.hasClients
//                               ? _pageController.page?.round() ?? 0
//                               : 0;
//                           return Text(
//                             '${currentPage + 1} of $pageCount',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 21,
//                               fontStyle: FontStyle.italic,
//                             ),
//                           );
//                         },
//                       ),
//               ),
//             ),
//           // Display recent drink names with animation
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [

              
      
//               Expanded(
//                 child: FadeTransition(
//                   opacity: _fadeAnimation,
//                   child: PageView.builder(
//                     //scrollDirection: Axis.vertical,
//                     controller: _pageController,
//                     itemCount: pageCount,
//                     itemBuilder: (context, pageIndex) {
//                       final startIndex = pageIndex * itemsPerPage;
//                       final endIndex = startIndex + itemsPerPage;
//                       final itemsToShow = drinkNames.sublist(
//                         startIndex,
//                         endIndex > drinkNames.length
//                             ? drinkNames.length
//                             : endIndex,
//                       );

//                       // Reversing the order of items to start from the bottom
//                       final reversedItems = itemsToShow.reversed.toList();

//                       return Column(
//                         mainAxisAlignment: MainAxisAlignment.end, // Start from the bottom
//                         children: reversedItems.map((drinkName) {
//                           return Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 29),
//                             child: Row(
//                               children: [
//                                 const SizedBox(width: 15),
//                                 FadeTransition(
//                                   opacity: _fadeAnimation,
//                                   child: const Iconify(
//                                     HeroiconsSolid.search,
//                                     size: 30,
//                                     color: Color.fromARGB(200, 255, 255, 255),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 10),
//                                 GestureDetector(
//                                   onTap: () {
//                                     _searchDrink(drinkName);
//                                   },
//                                   child: FadeTransition(
//                                     opacity: _fadeAnimation,
//                                     child: Text(
//                                       drinkName,
//                                       style: const TextStyle(
//                                         fontSize: 27.5,
//                                         color: Color.fromARGB(225, 255, 255, 255),
//                                         fontStyle: FontStyle.italic,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           );
//                         }).toList(),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 25),
//             ],
//           ),
//         ],
//       ),
//     ),
//   );
// }

// }
