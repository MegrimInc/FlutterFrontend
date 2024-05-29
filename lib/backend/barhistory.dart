import 'package:barzzy_app1/Backend/recommended.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BarHistory with ChangeNotifier {
  final List<String> _tappedBars = [];
  final Set<String> _allTappedIds = {}; 
  
  Set<String> get allTappedIds => _allTappedIds;
  List<String> get barIds => _tappedBars.toList();
  


// Method to reorder the list based on tapped bar IDs
  
void reorderList(String selectedBarId) {
  // Check if the selected ID is already at the front of the list
  if (_tappedBars.isNotEmpty && _tappedBars.first == selectedBarId) {
    return; // Do nothing if the same ID is at the front
  }

  // Otherwise, proceed with the reorder logic
  if (_tappedBars.contains(selectedBarId)) {
    _tappedBars.remove(selectedBarId); 
  }
  _tappedBars.insert(0, selectedBarId); // Move selected ID to the front
  notifyListeners();
}


/// Tap a bar ID
void tapBar(String barId, BuildContext context) { 
  if (!_tappedBars.contains(barId)) {
    _tappedBars.add(barId);
    //debugPrint('Tapped bar ID: $barId');
    addTappedId(barId, context); 
    notifyListeners();
  }
}


// Method to add a tapped ID to the set of all tapped IDs
void addTappedId(String barId, BuildContext context) {
    _allTappedIds.add(barId);
    //debugPrint('All tapped IDs: $_allTappedIds');

    // Notify the Recommended class with the updated list of tapped IDs
    Provider.of<Recommended>(context, listen: false).addTappedId(barId);
    notifyListeners();
}




}
