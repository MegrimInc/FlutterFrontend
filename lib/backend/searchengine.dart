import 'package:barzzy/Backend/database.dart';


class SearchService {
  final LocalDatabase localDatabase;

  SearchService(this.localDatabase);

  Map<int, Map<String, String>> searchMerchants(String searchText) {
    var merchants =
        localDatabase.getSearchableMerchantInfo(); // Get minimal data for search
    if (searchText.isEmpty) {
      return {};
    }

    // Use a map literal instead of the Map constructor
    var filteredMerchants = <int, Map<String, String>>{}; // Using map literal
    merchants.forEach((id, data) {
      if (data['name']!.toLowerCase().contains(searchText.toLowerCase())) {
        filteredMerchants[id] = data;
      }
    });
    return filteredMerchants;
  }
}