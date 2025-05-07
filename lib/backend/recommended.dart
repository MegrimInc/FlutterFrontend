import 'package:barzzy/Backend/localdatabase.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'merchanthistory.dart';

class Recommended with ChangeNotifier {
  final List<String> _recommendedMerchants = [];
  String? _currentTappedMerchantId;

  List<String> get merchantIds => _recommendedMerchants.toList();

  void setCurrentTappedMerchantId(String? merchantId) {
    _currentTappedMerchantId = merchantId;
  }

// RETURNS RECOMMENDED BARS AFTER FILTERING HAS BEEN DONE
  Future<void> fetchRecommendedMerchants(BuildContext context) async {
    final merchantHistory = Provider.of<MerchantHistory>(context, listen: false);
    _currentTappedMerchantId = merchantHistory.currentTappedMerchantId;
    //print('Current Tapped Merchant Id: $_currentTappedMerchantId');

    // ignore: await_only_futures
    final allMerchantIds = await LocalDatabase().getAllMerchantIds();

    // Print all merchant Ids before filtering
    //print('All Merchant Ids: $allMerchantIds');

    // Filter out the current tapped merchant Id and take the first 5
    final recommendedIds =
        allMerchantIds.where((id) => id != _currentTappedMerchantId).take(5).toList();

    //print('Recommended Ids after filtering: $recommendedIds');
    _recommendedMerchants.clear(); // Clear the list before adding new merchants
    _recommendedMerchants.addAll(recommendedIds);
    notifyListeners();
  }
}