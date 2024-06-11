import 'package:barzzy_app1/HomePage/popup.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:popover/popover.dart';
import 'package:barzzy_app1/Backend/bardatabase.dart';
import 'package:barzzy_app1/MenuPage/menu.dart'; 
class BarBottomSheet extends StatelessWidget {
  final String barId;
  

  const BarBottomSheet({
    super.key,
    required this.barId,
  });

  @override
  Widget build(BuildContext context) {
    final bar = BarDatabase.getBarById(barId);
    
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.718,
      child: Column(
        children: [
          Container(
              height: 88.3,
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.black,
                border: const Border(
                  top: BorderSide(
                    color: Color.fromARGB(255, 126, 126, 126),
                    width: 0.1,
                  ),
                ),
              ),
              child: Column(children: [
                
                //DRAG BAR

                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                //TOP ROW OF BUTTONS

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.more_horiz,
                        size: 35,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        showPopover(
                            context: context,
                            bodyBuilder: (context) => const Popup(),
                            height: 100,
                            width: 100,
                            backgroundColor: Colors.grey,
                            direction: PopoverDirection.top);
                      },
                    ),

          

                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '@',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  Colors.grey, // White color for the '@' symbol
                              fontWeight:
                                  FontWeight.normal, // Default font weight
                              fontFamily: DefaultTextStyle.of(context)
                                  .style
                                  .fontFamily, // Default font family
                            ),
                          ),
                          TextSpan(
                            text: bar?.tag ?? 'No Tag',
                            style: GoogleFonts.megrim(
                              fontSize: 16,
                              color: Colors.grey, // Grey color for the barName
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.rotate(
                      angle: -0.785398,
                      child: IconButton(
                          icon: const Icon(Icons.arrow_forward,
                              size: 30, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MenuPage(barId: barId),
                              ),
                            );
                          }),
                    ),
                  

                  ],
                ),
                 const SizedBox(height: 50,),
                    const Text('Shots'),
                    const SizedBox(height: 50),
                    const Text('Vodka')
              ])),
        ],
      ),
    );
  }
}

