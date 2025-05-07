import 'dart:convert';

import 'package:barzzy/Backend/bar.dart';
import 'package:barzzy/Backend/categories.dart';
import 'package:barzzy/Backend/drink.dart';
import 'package:barzzy/Backend/localdatabase.dart';
import 'package:barzzy/config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class User extends ChangeNotifier {
  static final User _singleton = User._internal();

  factory User() {
    return _singleton;
  }

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

  Future<void> checkForBar(String barId) async {
    LocalDatabase localDatabase = LocalDatabase();

    try {
      // Check if the bar exists in the local database
      if (!localDatabase.bars.containsKey(barId)) {
        debugPrint(
            "Bar with ID $barId not found in local database. Fetching details...");

        final response = await http
            .get(Uri.parse("${AppConfig.postgresApiBaseUrl}/customer/$barId"));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          debugPrint("Bar details fetched: $data");

          // Parse the bar and add it to the local database
          final Bar bar = Bar.fromJson(data);
          localDatabase.addBar(bar);
          debugPrint("Bar with ID $barId added to the local database.");
        } else {
          throw Exception(
              "Failed to fetch bar details. Status code: ${response.statusCode}");
        }
      } else {
        debugPrint("Bar with ID $barId found in local database.");
      }

      debugPrint("Tags and drinks fetched for bar ID $barId.");
    } catch (error) {
      debugPrint("Error in checkForBar for barId $barId: $error");
    }
  }

  Future<void> fetchTagsAndDrinks(String barId) async {
    debugPrint('Fetching drinks for bar ID: $barId');

    LocalDatabase localDatabase = LocalDatabase();

    checkForBar(barId);

    if (categoriesExistForBar(barId)) {
      debugPrint('Categories already exist for bar $barId, skipping fetch.');
      return; // Exit early if categories already exist
    }

    // KEEP PLEASE
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


    final url = Uri.parse(
        '${AppConfig.postgresApiBaseUrl}/customer/getAllItemsByMerchant/$barId');
    final response = await http.get(url);


    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      debugPrint('Drinks JSON response for bar $barId: $jsonResponse');

      for (var drinkJson in jsonResponse) {
        String? drinkId = drinkJson['itemId']?.toString();
        //debugPrint('Processing drink: $drinkJson');

        if (drinkId != null) {
          Drink drink = Drink.fromJson(drinkJson);
          localDatabase.addDrink(drink);

          debugPrint('Drink with ID: ${drink.itemId} added to LocalDatabase.');

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

          for (String tagId in drink.categories) {
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
}
