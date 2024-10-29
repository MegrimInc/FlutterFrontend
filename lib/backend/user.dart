import 'dart:convert';

import 'package:barzzy/Backend/categories.dart';
import 'package:barzzy/Backend/drink.dart';
import 'package:barzzy/Backend/localdatabase.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class User extends ChangeNotifier {
  static final User _singleton = User._internal();

  factory User() {
    return _singleton;
  }

   // ignore: unused_field
   final List<int> _defaultTagOrder = [
    179, 172, 175, 174, 173, 176, 
    177, 186, 178, 183, 184, 181
  ];

   final Map<int, int> categoryRanks = {
    172: 0, 173: 0, 174: 0, 175: 0, 176: 0, 177: 0, 
    178: 0, 179: 0, 181: 0, 183: 0, 184: 0, 186: 0
  };

  User._internal();

  // Map to store Categories objects with barId as the key
  Map<String, Categories> categoriesMap = {};

  void addCategories(String barId, Categories categories) {
    categoriesMap[barId] = categories;
    notifyListeners();
  }

  // Check if Categories already exist for a barId
  bool categoriesExistForBar(String barId) {
    return categoriesMap.containsKey(barId);
  }

  // Method to get full list of drink IDs for a bar by categories
  Map<String, List<int>> getFullDrinkListByBarId(String barId) {
    final categories = categoriesMap[barId];
    return {
      'tag172': categories?.tag172 ?? [],
      'tag173': categories?.tag173 ?? [],
      'tag174': categories?.tag174 ?? [],
      'tag175': categories?.tag175 ?? [],
      'tag176': categories?.tag176 ?? [],
      'tag177': categories?.tag177 ?? [],
      'tag178': categories?.tag178 ?? [],
      'tag179': categories?.tag179 ?? [],
      'tag181': categories?.tag181 ?? [],
      'tag183': categories?.tag183 ?? [],
      'tag184': categories?.tag184 ?? [],
      'tag186': categories?.tag186 ?? [],
    };
  }

//   Map<String, List<int>> getFullDrinkListByBarId(String barId) {
//   final categories = categoriesMap[barId];
//   if (categories == null) return {}; // Handle null case

//   // Determine if all ranks are zero
//   bool allRanksZero = categoryRanks.values.every((rank) => rank == 0);
//    debugPrint('All ranks zero: $allRanksZero'); // Debug statement

//    categoryRanks.forEach((key, value) {
//       debugPrint('Category $key Rank: $value');
//     });

//   // Get the sorted category order
//   List<int> sortedCategories;
//   if (allRanksZero) {
//     // Use default order if all ranks are zero
//     sortedCategories = List<int>.from(_defaultTagOrder);
//   } else {
//     // Sort categories by rank in descending order
//     List<MapEntry<int, int>> entries = categoryRanks.entries.toList();
//     entries.sort((a, b) => b.value.compareTo(a.value));

//     // Extract the sorted category keys
//     sortedCategories = entries.map((entry) => entry.key).toList();
//   }

//   // Build the drink list map according to the sorted category order
//   Map<String, List<int>> sortedDrinkMap = {};

//   for (int tag in sortedCategories) {
//     switch (tag) {
//       case 172:
//         sortedDrinkMap['tag172'] = categories.tag172;
//         break;
//       case 173:
//         sortedDrinkMap['tag173'] = categories.tag173;
//         break;
//       case 174:
//         sortedDrinkMap['tag174'] = categories.tag174;
//         break;
//       case 175:
//         sortedDrinkMap['tag175'] = categories.tag175;
//         break;
//       case 176:
//         sortedDrinkMap['tag176'] = categories.tag176;
//         break;
//       case 177:
//         sortedDrinkMap['tag177'] = categories.tag177;
//         break;
//       case 178:
//         sortedDrinkMap['tag178'] = categories.tag178;
//         break;
//       case 179:
//         sortedDrinkMap['tag179'] = categories.tag179;
//         break;
//       case 181:
//         sortedDrinkMap['tag181'] = categories.tag181;
//         break;
//       case 183:
//         sortedDrinkMap['tag183'] = categories.tag183;
//         break;
//       case 184:
//         sortedDrinkMap['tag184'] = categories.tag184;
//         break;
//       case 186:
//         sortedDrinkMap['tag186'] = categories.tag186;
//         break;
//     }
//   }

//   return sortedDrinkMap;
// }




  Future<void> fetchTagsAndDrinks(String barId) async {
    debugPrint('Fetching drinks for bar ID: $barId');

    LocalDatabase localDatabase = LocalDatabase();

    if (categoriesExistForBar(barId)) {
      debugPrint('Categories already exist for bar $barId, skipping fetch.');
      return; // Exit early if categories already exist
    }

    // ignore: unused_local_variable
    List<MapEntry<int, String>> tagList = [
      const MapEntry(179, 'lager'),
      const MapEntry(172, 'vodka'),
      const MapEntry(175, 'tequila'),
      const MapEntry(174, 'whiskey'),
      const MapEntry(173, 'gin'),
      const MapEntry(176, 'brandy'),
      const MapEntry(177, 'rum'),
      const MapEntry(186, 'seltzer'),
      const MapEntry(178, 'ale'),
      const MapEntry(183, 'red wine'),
      const MapEntry(184, 'white wine'),
      const MapEntry(181, 'virgin'),
    ];

    Categories categories = Categories(
      barId: int.parse(barId),
      tag172: [],
      tag173: [],
      tag174: [],
      tag175: [],
      tag176: [],
      tag177: [],
      tag178: [],
      tag179: [],
      tag181: [],
      tag183: [],
      tag184: [],
      tag186: [],
    );

    final url =
        Uri.parse('https://www.barzzy.site/bars/getAllDrinksByBar/$barId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      //debugPrint('Drinks JSON response for bar $barId: $jsonResponse');

      for (var drinkJson in jsonResponse) {
        String? drinkId = drinkJson['drinkId']?.toString();
        //debugPrint('Processing drink: $drinkJson');

        if (drinkId != null) {
          Drink drink = Drink.fromJson(drinkJson);
          localDatabase.addDrink(drink);
          //debugPrint('Added drink with ID: $drinkId to bar $barId');

          if (drink.image.isNotEmpty) {
            final cachedImage = CachedNetworkImageProvider(drink.image);
            cachedImage.resolve(const ImageConfiguration()).addListener(
                  ImageStreamListener(
                    (ImageInfo image, bool synchronousCall) {
                      debugPrint(
                          'Drink image successfully cached: ${drink.image}');
                    },
                    onError: (dynamic exception, StackTrace? stackTrace) {
                      debugPrint('Failed to cache drink image: $exception');
                    },
                  ),
                );
          }

          for (String tagId in drink.tagId) {
            //debugPrint('Processing tagId: $tagId for drinkId: $drinkId');
            switch (int.parse(tagId)) {
              case 172:
                categories.tag172.add(int.parse(drinkId));
                break;
              case 173:
                categories.tag173.add(int.parse(drinkId));
                break;
              case 174:
                categories.tag174.add(int.parse(drinkId));
                break;
              case 175:
                categories.tag175.add(int.parse(drinkId));
                break;
              case 176:
                categories.tag176.add(int.parse(drinkId));
                break;
              case 177:
                categories.tag177.add(int.parse(drinkId));
                break;
              case 178:
                categories.tag178.add(int.parse(drinkId));
                break;
              case 179:
                categories.tag179.add(int.parse(drinkId));
                break;
              case 181:
                categories.tag181.add(int.parse(drinkId));
                break;
              case 183:
                categories.tag183.add(int.parse(drinkId));
                break;
              case 184:
                categories.tag184.add(int.parse(drinkId));
                break;
              case 186:
                categories.tag186.add(int.parse(drinkId));
                break;
              default:
              //debugPrint('Unknown tagId: $tagId for drinkId: $drinkId');
            }
          }
        } else {
          debugPrint('Warning: Drink ID is null for drink: $drinkJson');
        }
      }

      addCategories(barId, categories);
      debugPrint(
          'Drinks for bar $barId have been categorized and added to the User object.');
    } else {
      debugPrint(
          'Failed to load drinks for bar $barId. Status code: ${response.statusCode}');
    }

    debugPrint('Finished processing drinks for barId: $barId');
  }


  // New: Update category rank by a delta (increase or decrease)
  void updateCategoryRank(int tagId, int delta) {
    if (categoryRanks.containsKey(tagId)) {
      categoryRanks[tagId] = (categoryRanks[tagId] ?? 0) + delta;
      notifyListeners();
    }
  }
}
