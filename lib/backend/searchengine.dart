import 'package:barzzy_app1/Backend/bardatabase.dart';

class SearchService {
  final BarDatabase barDatabase;

  SearchService(this.barDatabase);

  Map<String, Map<String, String>> searchBars(String searchText) {
    var bars = barDatabase.getSearchableBarInfo(); // Get minimal data for search
    if (searchText.isEmpty) {
      return {};
    }
    
    // Use a map literal instead of the Map constructor
    var filteredBars = <String, Map<String, String>>{};  // Using map literal
    bars.forEach((id, data) {
      if (data['name']!.toLowerCase().contains(searchText.toLowerCase())) {
        filteredBars[id] = data;
      }
    });
    return filteredBars;
  }
}
