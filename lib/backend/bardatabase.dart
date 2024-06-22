import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'bar.dart';

class BarDatabase with ChangeNotifier {
  static final BarDatabase _singleton = BarDatabase._internal();

  factory BarDatabase() {
    return _singleton;
  }

  BarDatabase._internal();

  final Map<String, Bar> _bars = {};

  final Uuid _uuid = const Uuid();
 
  // Method to add a new bar, generating an ID for it
  void addBar(Bar bar) {
    String newId = _uuid.v4(); // Generate a unique ID
    _bars[newId] = Bar(
        name: bar.name, 
        address: bar.address, 
        drinks: bar.drinks, 
        tag: bar.tag,
        nameAndTagMap: bar.nameAndTagMap);
    notifyListeners();
    
  }

  // Method to get minimal information necessary for search
  Map<String, Map<String, String>> getSearchableBarInfo() {
    return _bars.map((id, bar) =>
        MapEntry(id, {'name': bar.name ?? '', 'address': bar.address ?? ''}));
        
  }



  void removeBar(String id) {
    if (_bars.remove(id) != null) {
      notifyListeners();
    }
  }

 //Method to get all bar IDs
  List<String> getAllBarIds() {
    return _bars.keys.toList();
  }

  

static Bar? getBarById(String id) {
    return _singleton._bars[id];
  }

 // Method to get bar and drink IDs
  static List<String> getBarAndDrinkIds(String barId) {
    final List<String> drinkIds = [];
    final Bar? bar = _singleton._bars[barId];
    if (bar != null) {
      drinkIds.addAll(bar.drinks!.map((drink) => drink.id));
    }
    drinkIds.insert(0, barId);
    return drinkIds;
  }


}





