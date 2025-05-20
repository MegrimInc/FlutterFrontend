// import 'dart:convert';

// import 'package:barzzy/DTO/merchant.dart';
// import 'package:barzzy/DTO/item.dart';
// import 'package:barzzy/Backend/database.dart';
// import 'package:barzzy/config.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// class Categories extends ChangeNotifier {
//   static final Categories _singleton = Categories._internal();

//   factory Categories() {
//     return _singleton;
//   }

//   Categories._internal();

//   // Map to store Categories objects with merchantId as the key
//   Map<int, Categories> categoriesMap = {};

//   void addCategories(int merchantId, Categories categories) {
//     categoriesMap[merchantId] = categories;
//     notifyListeners();
//   }

//   // Check if Categories already exist for a merchantId
//   bool categoriesExistForMerchant(int merchantId) {
//     return categoriesMap.containsKey(merchantId);
//   }

//   // Method to get full list of item Ids for a merchant by categories
//   Map<String, List<int>> getFullItemListByMerchantId(int merchantId) {
//     final categories = categoriesMap[merchantId];
//     return {
//       'tag172': categories?.tag172 ?? [],
//       'tag173': categories?.tag173 ?? [],
//       'tag174': categories?.tag174 ?? [],
//       'tag175': categories?.tag175 ?? [],
//       'tag176': categories?.tag176 ?? [],
//       'tag177': categories?.tag177 ?? [],
//       'tag178': categories?.tag178 ?? [],
//       'tag179': categories?.tag179 ?? [],
//       'tag181': categories?.tag181 ?? [],
//       'tag183': categories?.tag183 ?? [],
//       'tag184': categories?.tag184 ?? [],
//       'tag186': categories?.tag186 ?? [],
//     };
//   }

//   Future<void> checkForMerchant(int merchantId) async {
//     LocalDatabase localDatabase = LocalDatabase();

//     try {
//       // Check if the merchant exists in the local database
//       if (!localDatabase.merchants.containsKey(merchantId)) {
//         debugPrint(
//             "Merchant with Id $merchantId not found in local database. Fetching details...");

//         final response = await http
//             .get(Uri.parse("${AppConfig.postgresApiBaseUrl}/customer/$merchantId"));

//         if (response.statusCode == 200) {
//           final data = jsonDecode(response.body);
//           debugPrint("Merchant details fetched: $data");

//           // Parse the merchant and add it to the local database
//           final Merchant merchant = Merchant.fromJson(data);
//           localDatabase.addMerchant(merchant);
//           debugPrint("Merchant with Id $merchantId added to the local database.");
//         } else {
//           throw Exception(
//               "Failed to fetch merchant details. Status code: ${response.statusCode}");
//         }
//       } else {
//         debugPrint("Merchant with Id $merchantId found in local database.");
//       }

//       debugPrint("Tags and items fetched for merchant Id $merchantId.");
//     } catch (error) {
//       debugPrint("Error in checkForMerchant for merchantId $merchantId: $error");
//     }
//   }

//   Future<void> fetchCategoriesAndItems(int merchantId) async {
//     debugPrint('Fetching items for merchant Id: $merchantId');

//     LocalDatabase localDatabase = LocalDatabase();

//     checkForMerchant(merchantId);

//     if (categoriesExistForMerchant(merchantId)) {
//       debugPrint('Categories already exist for merchant $merchantId, skipping fetch.');
//       return; // Exit early if categories already exist
//     }

//     // KEEP PLEASE
//     // ignore: unused_local_variable
//     List<MapEntry<int, String>> tagList = [
//       const MapEntry(179, 'lager'),
//       const MapEntry(172, 'vodka'),
//       const MapEntry(175, 'tequila'),
//       const MapEntry(174, 'whiskey'),
//       const MapEntry(173, 'gin'),
//       const MapEntry(176, 'brandy'),
//       const MapEntry(177, 'rum'),
//       const MapEntry(186, 'seltzer'),
//       const MapEntry(178, 'ale'),
//       const MapEntry(183, 'red wine'),
//       const MapEntry(184, 'white wine'),
//       const MapEntry(181, 'virgin'),
//     ];

   


//     final url = Uri.parse(
//         '${AppConfig.postgresApiBaseUrl}/customer/getInventoryByMerchant/$merchantId');
//     final response = await http.get(url);


//     if (response.statusCode == 200) {
//       final List<dynamic> jsonResponse = jsonDecode(response.body);
//       debugPrint('Items JSON response for merchant $merchantId: $jsonResponse');

//       for (var itemJson in jsonResponse) {
//         String? itemId = itemJson['itemId']?.toString();
//         //debugPrint('Processing item: $itemJson');

//         if (itemId != null) {
//           Item item = Item.fromJson(itemJson);
//           localDatabase.addItem(item);

//           debugPrint('Item with Id: ${item.itemId} added to LocalDatabase.');

//           if (item.image.isNotEmpty) {
//             final cachedImage = CachedNetworkImageProvider(item.image);
//             cachedImage.resolve(const ImageConfiguration()).addListener(
//                   ImageStreamListener(
//                     (ImageInfo image, bool synchronousCall) {
//                       debugPrint(
//                           'Item image successfully cached: ${item.image}');
//                     },
//                     onError: (dynamic exception, StackTrace? stackTrace) {
//                       debugPrint('Failed to cache item image: $exception');
//                     },
//                   ),
//                 );
//           }

//           for (String tagId in item.categories) {
//             //debugPrint('Processing tagId: $tagId for itemId: $itemId');
//             switch (int.parse(tagId)) {
//               case 172:
//                 categories.tag172.add(int.parse(itemId));
//                 break;
//               case 173:
//                 categories.tag173.add(int.parse(itemId));
//                 break;
//               case 174:
//                 categories.tag174.add(int.parse(itemId));
//                 break;
//               case 175:
//                 categories.tag175.add(int.parse(itemId));
//                 break;
//               case 176:
//                 categories.tag176.add(int.parse(itemId));
//                 break;
//               case 177:
//                 categories.tag177.add(int.parse(itemId));
//                 break;
//               case 178:
//                 categories.tag178.add(int.parse(itemId));
//                 break;
//               case 179:
//                 categories.tag179.add(int.parse(itemId));
//                 break;
//               case 181:
//                 categories.tag181.add(int.parse(itemId));
//                 break;
//               case 183:
//                 categories.tag183.add(int.parse(itemId));
//                 break;
//               case 184:
//                 categories.tag184.add(int.parse(itemId));
//                 break;
//               case 186:
//                 categories.tag186.add(int.parse(itemId));
//                 break;
//               default:
//               //debugPrint('Unknown tagId: $tagId for itemId: $itemId');
//             }
//           }
//         } else {
//           debugPrint('Warning: Item Id is null for item: $itemJson');
//         }
//       }

//       addCategories(merchantId, categories);
//       debugPrint(
//           'Items for merchant $merchantId have been categorized and added to the Customer object.');
//     } else {
//       debugPrint(
//           'Failed to load items for merchant $merchantId. Status code: ${response.statusCode}');
//     }

//     debugPrint('Finished processing items for merchantId: $merchantId');
//   }
// }