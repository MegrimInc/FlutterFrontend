import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'bar.dart';

class BarDatabase with ChangeNotifier {
  final Map<String, Bar> _bars = {};
  
  final Uuid _uuid = const Uuid();

  // Method to add a new bar, generating an ID for it
  void addBar(Bar bar) {
    String newId = _uuid.v4(); // Generate a unique ID
    _bars[newId] = Bar(
      name: bar.name,
      address: bar.address,
      drinks: bar.drinks
    );
    notifyListeners();
  }


 // Method to get minimal information necessary for search
  Map<String, Map<String, String>> getSearchableBarInfo() {
    return _bars.map((id, bar) =>
      MapEntry(id, {'name': bar.name ?? '', 'address': bar.address ?? ''}));
  }




  // Retrieving, updating, and removing bars using their IDs
  Bar? getBarById(String id) => _bars[id];
  void updateBar(String id, Bar updatedBar) {
    if (_bars.containsKey(id)) {
      _bars[id] = updatedBar;
      notifyListeners();
    }
  }
  void removeBar(String id) {
    if (_bars.remove(id) != null) {
      notifyListeners();
    }
  }
}
