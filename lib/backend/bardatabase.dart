import 'package:barzzy_app1/Backend/response.dart';
import 'package:barzzy_app1/Backend/user.dart';
import 'package:flutter/material.dart';
import 'bar.dart';

class BarDatabase with ChangeNotifier {
  static final BarDatabase _singleton = BarDatabase._internal();

  factory BarDatabase() {
    return _singleton;
  }

  BarDatabase._internal();

  final Map<String, Bar> _bars = {};

  
 
  // Method to add a new bar, generating an ID for it
   void addBar(Bar bar) {
    if (bar.id != null) {
      _bars[bar.id!] = bar;
      notifyListeners();
    } else {
      debugPrint('Bar ID is null, cannot add to database.');
    }
  }

  // Method to get minimal information necessary for search
  Map<String, Map<String, String>> getSearchableBarInfo() {
    return _bars.map((id, bar) =>
        MapEntry(id, {'name': bar.name ?? '', 'address': bar.address ?? ''}));
        
  }


 //Method to get all bar IDs
  List<String> getAllBarIds() {
    return _bars.keys.toList();
  }

  
static Bar? getBarById(String id) {
    return _singleton._bars[id];
  }


void searchDrinks(String query, User user, String barId) {
    Set<String> filteredIdsSet = {};
    user.addQueryToHistory(barId, query);
    query = query.toLowerCase().replaceAll(' ', '');

    debugPrint('Search query received: $query');

    // nameAndTagMap?.forEach((key, value) {
    //   // Check if the lowercase key contains the lowercase query as a substring
    //   if (key.toLowerCase().contains(query)) {
    //     filteredIdsSet.addAll(value);
    //   }
    // });
    List<String> filteredIds = filteredIdsSet.toList();

    debugPrint(
        'Filtered IDs for query $query: $filteredIds'); // Print the filtered IDs

    if (filteredIds.isEmpty) {
      Response().addNegativeResponse(user, barId);
    } else {
      Response().addPositiveResponse(user, barId);
    }

    user.addSearchQuery(barId, query, filteredIds);
    //user.addQueryToHistory(barId, query);
  }







}





