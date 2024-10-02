import 'package:barzzy/Backend/localdatabase.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'barhistory.dart';

class Recommended with ChangeNotifier {
  final List<String> _recommendedBars = [];
  String? _currentTappedBarId;

  List<String> get barIds => _recommendedBars.toList();

  void setCurrentTappedBarId(String? barId) {
    _currentTappedBarId = barId;
  }

// RETURNS RECOMMENDED BARS AFTER FILTERING HAS BEEN DONE
  Future<void> fetchRecommendedBars(BuildContext context) async {
    final barHistory = Provider.of<BarHistory>(context, listen: false);
    _currentTappedBarId = barHistory.currentTappedBarId;
    //print('Current Tapped Bar ID: $_currentTappedBarId');

    // ignore: await_only_futures
    final allBarIds = await LocalDatabase().getAllBarIds();

    // Print all bar IDs before filtering
    //print('All Bar IDs: $allBarIds');

    // Filter out the current tapped bar ID and take the first 5
    final recommendedIds =
        allBarIds.where((id) => id != _currentTappedBarId).take(5).toList();

    //print('Recommended IDs after filtering: $recommendedIds');
    _recommendedBars.clear(); // Clear the list before adding new bars
    _recommendedBars.addAll(recommendedIds);
    notifyListeners();
  }
}
