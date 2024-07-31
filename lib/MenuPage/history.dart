import 'package:flutter/material.dart';


class HistorySheet extends StatelessWidget {
  final String barId;
  final VoidCallback onClose;
  

  const HistorySheet({
    super.key,
    required this.barId,
    required this.onClose,
  });

  

  @override
  Widget build(BuildContext context) {
    
    
    return GestureDetector(
      onTap: onClose,
      child: const Scaffold(
        backgroundColor: Color.fromARGB(92, 83, 82, 82),
       
        body: Column( 
          
          children: [
            
          ],
        ),
      ),
    );
  }
}

