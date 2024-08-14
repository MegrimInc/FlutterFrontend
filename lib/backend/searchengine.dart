import 'package:barzzy_app1/Backend/localdatabase.dart';

class SearchService {
  final LocalDatabase localDatabase;

  SearchService(this.localDatabase);

  Map<String, Map<String, String>> searchBars(String searchText) {
    var bars = localDatabase.getSearchableBarInfo(); // Get minimal data for search
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
