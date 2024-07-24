import 'package:barzzy_app1/Backend/recommended.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';



class BarHistory with ChangeNotifier {
  String? _currentTappedBarId;
  BuildContext? _context;

  // Method to get the currently tapped bar ID
  String? get currentTappedBarId => _currentTappedBarId;

  BarHistory() {
    _loadTappedBarId();
  }

  

  // Method to load the tapped bar ID from SharedPreferences
  Future<void> _loadTappedBarId() async {
    final prefs = await SharedPreferences.getInstance();
    _currentTappedBarId = prefs.getString('currentTappedBarId');
  _updateRecommendations();
    notifyListeners();
    // Fetch recommended bars after loading tapped bar ID
    
    
  }

  // Method to save the tapped bar ID to SharedPreferences
  Future<void> _saveTappedBarId() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentTappedBarId != null) {
      await prefs.setString('currentTappedBarId', _currentTappedBarId!);
    } else {
      await prefs.remove('currentTappedBarId');
    }
  }

  // Method to set a new tapped bar ID
  void setTappedBarId(String barId) {
    _currentTappedBarId = barId;
    _saveTappedBarId(); // Save the new tapped bar ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners(); // Notify listeners after the build phase
      _updateRecommendations();
    });
  }


   // Method to clear the current tapped bar ID from memory and SharedPreferences
  Future<void> clearTappedBarId() async {
    _currentTappedBarId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentTappedBarId');
    _updateRecommendations();
    notifyListeners();
   
  }

  void _updateRecommendations() {
    if (_context != null) {
      Provider.of<Recommended>(_context!, listen: false).fetchRecommendedBars(_context!);
    }
  }

  void setContext(BuildContext context) {
    _context = context;
    _updateRecommendations();
  }
}
