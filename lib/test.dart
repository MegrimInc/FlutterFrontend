// import 'package:flutter/material.dart';
// import 'package:flutter_chat_bubble/chat_bubble.dart';

// class ChatScreen extends StatelessWidget {
//   const ChatScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Chat Bubbles')),
//       body: Column(
//         children: <Widget>[
//           ChatBubble(
//             clipper: ChatBubbleClipper1(type: BubbleType.receiverBubble),
//             alignment: Alignment.topLeft,
//             margin: const EdgeInsets.only(top: 20),
//             backGroundColor: const Color(0xffE7E7ED),
//             child: Container(
//               constraints: BoxConstraints(
//                 maxWidth: MediaQuery.of(context).size.width * 0.7,
//               ),
//               child: const Text(
//                 'Hi, how are you?',
//                 style: TextStyle(color: Colors.black),
//               ),
//             ),
//           ),
//           ChatBubble(
//             clipper: ChatBubbleClipper1(type: BubbleType.sendBubble),
//             alignment: Alignment.topRight,
//             margin: const EdgeInsets.only(top: 20),
//             backGroundColor: Colors.blue,
//             child: Container(
//               constraints: BoxConstraints(
//                 maxWidth: MediaQuery.of(context).size.width * 0.7,
//               ),
//               child: const Text(
//                 'I am good, thanks!',
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
