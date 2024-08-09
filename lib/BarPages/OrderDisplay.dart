 import 'dart:convert';

 
 import 'package:barzzy_app1/Backend/order.dart';
import 'package:flutter/material.dart';
 import 'package:http/http.dart' as http;

 class OrderDisplay extends StatefulWidget {
   const OrderDisplay({super.key});

   @override
   State<OrderDisplay> createState() => _OrderDisplayState();
 }

 class _OrderDisplayState extends State<OrderDisplay> {
   late Future<List<Order>> ordersFuture;

   @override
   void initState() {
     super.initState();
      //Initialize the data fetching
     ordersFuture = fetchData();
   }

   Future<List<Order>> fetchData() async {
     final Uri url = Uri.parse('https:www.barzzy.site/hello');
     try {
       final response = await http.get(url);
       if (response.statusCode == 200) {
          //Decode the JSON response
         final List<dynamic> jsonResponse = jsonDecode(response.body);
          //Convert JSON response to List<Order>
         return jsonResponse.map((json) => Order.fromJson(json)).toList();
       } else {
         throw Exception('Failed to load data');
       }
     } catch (e) {
        //Handle exceptions or errors
       return [];
     }
   }

   void invalidCredentialsMessage() {
     showDialog(
         context: context,
         builder: (context) {
           return const AlertDialog(
             backgroundColor: Color.fromARGB(255, 255, 190, 68),
             title: Center(
                 child: Text(
               'Invalid name. Please check your fields.',
               style: TextStyle(
                 color: Color.fromARGB(255, 30, 30, 30),
                 fontWeight: FontWeight.bold,
               ),
             )),
           );
         });
   }

   @override
   Widget build(BuildContext context) {
     return Scaffold(
       backgroundColor: const Color.fromARGB(255, 15, 15, 15),
       body: SafeArea(
         child: FutureBuilder<List<Order>>(
           future: ordersFuture,
           builder: (context, snapshot) {
             if (snapshot.connectionState == ConnectionState.waiting) {
                //Show a loading indicator while waiting for data
               return const Center(child: CircularProgressIndicator());
             } else if (snapshot.hasError) {
                //Show an error message if an error occurred
               return Center(child: Text('Error: ${snapshot.error}'));
             } else if (snapshot.hasData) {
                //Show the data once it is fetched
               final orders = snapshot.data!;
               return SingleChildScrollView(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     const SizedBox(height: 75),
                     const Icon(Icons.abc_outlined,
                         size: 100, color: Color.fromARGB(255, 15, 15, 15)),
                     const SizedBox(height: 100),
                      //Display the orders here
                     for (var order in orders)
                       Text(order.toString()),  //Adjust based on Order class implementation
                   ],
                 ),
               );
             } else {
               return const Center(child: Text('No data available'));
             }
           },
         ),
       ),
     );
   }
 }
