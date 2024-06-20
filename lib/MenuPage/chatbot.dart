// import 'package:animated_text_kit/animated_text_kit.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../Backend/user.dart'; // Assuming you have your User class imported

// class CaponeChatWidget extends StatefulWidget {
//   final Function(bool) onGreetingChanged;

//   const CaponeChatWidget({
//     super.key,
//     required this.onGreetingChanged,
//   });

//   @override
//   CaponeChatWidgetState createState() => CaponeChatWidgetState();
// }

// class CaponeChatWidgetState extends State<CaponeChatWidget> {
//   bool showGreeting = true;

//   @override
//   void initState() {
//     super.initState();
//     showGreeting = true; // Initially show greeting

//     // Listen to changes in User's last successful search
//     final user = Provider.of<User>(context, listen: false);
//     user.addListener(_handleUserChange);

//     // Determine initial greeting state based on last successful search
//     String? lastSearch = user.getLastSuccessfulSearch(user.currentBarId ?? '');
//     if (lastSearch != null && lastSearch.isNotEmpty) {
//       setState(() {
//         showGreeting = false;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     final user = Provider.of<User>(context, listen: false);
//     user.removeListener(_handleUserChange);
//     super.dispose();
//   }

//   void _handleUserChange() {
//     final user = Provider.of<User>(context, listen: false);
//     String? lastSearch = user.getLastSuccessfulSearch(user.currentBarId ?? '');
//     setState(() {
//       showGreeting = lastSearch == null || lastSearch.isEmpty;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final user = Provider.of<User>(context);
//     final String? currentBarId = user.currentBarId;

//     // Use currentBarId and user as needed
//     return SizedBox(
//       height: MediaQuery.of(context).viewInsets.bottom + 17,
//       child: Visibility(
//         visible: MediaQuery.of(context).viewInsets.bottom > 200,
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.only(top: 50.0),
//               child: DefaultTextStyle(
//                 style: const TextStyle(
//                   fontSize: 15.0,
//                   color: Colors.white,
//                 ),
//                 child: Center(
//                   child: AnimatedTextKit(
//                     animatedTexts: [
//                       TypewriterAnimatedText(
//                         showGreeting
//                             ? "Hi! What can I get for you?"
//                             : "Hmm, don't think we have that.",
//                         speed: const Duration(milliseconds: 15),
//                       ),
//                     ],
//                     totalRepeatCount: 1,
//                     pause: const Duration(milliseconds: 1000),
//                     displayFullTextOnTap: true,
//                     stopPauseOnTap: true,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(
//               height: 50,
//             ),
//             const Icon(
//               Icons.face,
//               size: 50,
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
