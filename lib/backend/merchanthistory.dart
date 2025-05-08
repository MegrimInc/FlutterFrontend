import 'package:barzzy/Backend/recommended.dart';
import 'package:barzzy/Backend/localdatabase.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MerchantHistory with ChangeNotifier {
  String? _currentTappedMerchantId;
  BuildContext? _context;

  // Method to get the currently tapped merchant Id
  String? get currentTappedMerchantId => _currentTappedMerchantId;

  MerchantHistory() {
    _loadTappedMerchantId();
  }

  // Method to load the tapped merchant Id from SharedPreferences
  Future<void> _loadTappedMerchantId() async {
    final prefs = await SharedPreferences.getInstance();
    _currentTappedMerchantId = prefs.getString('currentTappedMerchantId');
    _ensureTappedMerchantIdExists();
    _updateRecommendations();
    notifyListeners();
    // Fetch recommended merchants after loading tapped merchant Id
  }

  // Method to save the tapped merchant Id to SharedPreferences
  Future<void> _saveTappedMerchantId() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentTappedMerchantId != null) {
      await prefs.setString('currentTappedMerchantId', _currentTappedMerchantId!);
    } else {
      await prefs.remove('currentTappedMerchantId');
    }
  }

  // Method to set a new tapped merchant Id
  void setTappedMerchantId(String merchantId) {
    _currentTappedMerchantId = merchantId;
    _saveTappedMerchantId(); // Save the new tapped merchant Id
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners(); // Notify listeners after the build phase
      _updateRecommendations();
    });
    notifyListeners();
  }

  // Method to clear the current tapped merchant Id from memory and SharedPreferences
  Future<void> clearTappedMerchantId() async {
    _currentTappedMerchantId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentTappedMerchantId');
    _updateRecommendations();
    notifyListeners();
  }

  void _updateRecommendations() {
    if (_context != null) {
      Provider.of<Recommended>(_context!, listen: false)
          .fetchRecommendedMerchants(_context!);
    }
  }

  void _ensureTappedMerchantIdExists() {
    if (_currentTappedMerchantId == null || _currentTappedMerchantId!.isEmpty) {
      final merchantIds = LocalDatabase().getAllMerchantIds();

      if (merchantIds.isNotEmpty) {
        // Check if merchant_id 95 exists
        if (merchantIds.contains('95')) {
          setTappedMerchantId('95'); // Set merchant_id 95 as the tapped merchant Id
          debugPrint('Tapped merchant Id set to: 95');
        } else {
          // If merchant_id 95 doesn't exist, fallback to the first available merchant Id
          setTappedMerchantId(merchantIds.first);
          debugPrint('Tapped merchant Id set to: ${merchantIds.first}');
        }
      } else {
        debugPrint(
            'No merchants available in the LocalDatabase to set as tapped merchant.');
      }
    }
  }

  void setContext(BuildContext context) {
    _context = context;
    _updateRecommendations();
  }
}