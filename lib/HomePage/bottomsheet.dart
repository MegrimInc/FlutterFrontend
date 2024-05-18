import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import 'package:barzzy_app1/Backend/bardatabase.dart';
import 'package:barzzy_app1/MenuPage/menu.dart'; // Ensure to import your MenuPage

class BarBottomSheet extends StatelessWidget {
  final String barId;

  const BarBottomSheet({
    super.key,
    required this.barId,
  });

  @override
  Widget build(BuildContext context) {
    // final barDatabase = Provider.of<BarDatabase>(context);
    // final barName = barDatabase.getBarById(barId)?.tag ?? 'No Name';

    return Container(
      height: MediaQuery.of(context).size.height * 0.718,
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: const Border(
          top: BorderSide(
            color: Color.fromARGB(255, 126, 126, 126),
            width: 0.1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 150,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const SizedBox(width: 5),
              Column(
                children: [
                  
                  Text(
                    'Wait: 10 min',
                    style: GoogleFonts.sourceSans3(
                      fontSize: 15,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 77),
              const Icon(
                Icons.history_rounded,
                color: Colors.white,
                size: 30,
              ),
                              
                             
              const SizedBox(width: 90),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MenuPage(barId: barId),
                    ),
                  );
                },
                child: Text(
                  'See Menu',
                  style: GoogleFonts.sourceSans3(
                    fontSize: 15,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
