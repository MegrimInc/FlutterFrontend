import 'package:flutter/material.dart';


class BarBottomSheet extends StatelessWidget {
  final String barId;
  

  const BarBottomSheet({
    super.key,
    required this.barId,
  });

  @override
  Widget build(BuildContext context) {
    
    
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
              ])),
        ],
      ),
    );
  }
}

