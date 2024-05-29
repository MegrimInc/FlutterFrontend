import 'package:barzzy_app1/Backend/bardatabase.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'barhistory.dart';

class Recommended with ChangeNotifier {
  final List<String> _recommendedBars = [];
  final List<String> _tappedIds = [];

  List<String> get barIds => _recommendedBars.toList();


  // SET OF IDS THAT SHOULD NOT BE RECOMMENDED 
  void addTappedId(String barId) {
    _tappedIds.add(barId);
    // Use the tapped IDs for filtering the recommended list
    filterOutTappedBars();
}


// METHOD TO FILTER OUT THE IDS THAT SHOULD NOT BE RECOMMENDED 
  void filterOutTappedBars() {
    _recommendedBars.removeWhere((barId) => _tappedIds.contains(barId));
    //print('Tapped bars to be filtered out: $_tappedIds');
    notifyListeners();
    //print('Recommended bars after filtering: $_recommendedBars');
  }


// RETURNS RECOMMENDED BARS AFTER FILTERING HAS BEEN DONE
  Future<void> fetchRecommendedBars(BuildContext context) async {
    // ignore: await_only_futures
    final allBarIds = await BarDatabase().getAllBarIds(); // Use instance member directly
    // ignore: use_build_context_synchronously
    final tappedIds = Provider.of<BarHistory>(context, listen: false).allTappedIds.toList();
    final recommendedIds = allBarIds.where((id) => !tappedIds.contains(id)).take(5).toList();
    _recommendedBars.clear(); // Clear the list before adding new bars
    _recommendedBars.addAll(recommendedIds);
    filterOutTappedBars(); // Apply filtering to ensure no tapped IDs are included
  }

}
