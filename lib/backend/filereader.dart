import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:excel/excel.dart';
import 'bar.dart';
import 'drink.dart';
import 'bardatabase.dart';

class FileReader {
  final BarDatabase barDatabase;

  FileReader(this.barDatabase);

  Future<void> loadMenu() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      final excelFiles = manifestMap.keys.where(
          (path) => path.startsWith('lib/menus/') && path.endsWith('.xlsx'));

      for (final filePath in excelFiles) {
        final ByteData data = await rootBundle.load(filePath);
        var bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        var excel = Excel.decodeBytes(bytes);

        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table];
          if (sheet != null) {
            var barName = sheet.cell(CellIndex.indexByString('A1')).value.toString();
            var barAddress = sheet.cell(CellIndex.indexByString('D1')).value.toString();
            var currentBar = Bar(name: barName, address: barAddress);
            

            for (var row in sheet.rows.skip(2)) {  // Assuming the first two rows are headers
              if (row[0] != null && row[0]!.value.toString().isNotEmpty) {
                var drinkName = row[1]!.value.toString();
                var drinkDescription = row[2]?.value?.toString() ?? '';
                var drinkPrice = double.tryParse(row[3]?.value?.toString() ?? '0') ?? 0;
                var drinkAlcohol = double.tryParse(row[4]?.value?.toString() ?? '0') ?? 0;
                var drinkType = row[0]?.value?.toString() ?? 'Unknown Type';
                List<String> drinkIngredients = [];

                for (int i = 8; i <= 13; i++) {
                  var cellValue = row[i]?.value?.toString().trim() ?? '';
                  if (cellValue.isNotEmpty && cellValue.toUpperCase() != "N/A") {
                    drinkIngredients.add(cellValue);
                  }
                }

                // Create the drink without specifying an ID
                Drink drink = Drink("", drinkName, drinkDescription, drinkPrice,
                    drinkAlcohol, drinkType, drinkIngredients);
                currentBar.addDrink(drink);
              }
            }
            barDatabase.addBar(currentBar);
          }
        }
      }
    } catch (e) {
      debugPrint('Error reading files: $e');
    }
  }
}
