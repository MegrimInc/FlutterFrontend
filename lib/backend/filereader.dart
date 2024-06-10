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
          (path) => path.startsWith('lib/MenuPage/menus') && path.endsWith('.xlsx'));

      for (final filePath in excelFiles) {
        final ByteData data = await rootBundle.load(filePath);
        var bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        var excel = Excel.decodeBytes(bytes);

        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table];
          if (sheet != null) {
            var tag = extractTagFromSheetName(table);
            var barName = sheet.cell(CellIndex.indexByString('A1')).value.toString();
            var barAddress = sheet.cell(CellIndex.indexByString('D1')).value.toString();
            var currentBar = Bar(name: barName, address: barAddress, tag: tag);
            

            for (var row in sheet.rows.skip(2)) {  // Assuming the first two rows are headers
              if (row[0] != null && row[0]!.value.toString().isNotEmpty) {
                var drinkStyle = row[0]!.value.toString();
                var drinkType = row[1]?.value?.toString() ?? 'Unknown Type';
                var drinkName = row[2]!.value.toString();
                var drinkDescription = row[4]?.value?.toString() ?? '';
                var drinkPrice = double.tryParse(row[7]?.value?.toString() ?? '0') ?? 0;
                var drinkAlcohol = double.tryParse(row[8]?.value?.toString() ?? '0') ?? 0;
                
                var drinkImage = 'lib/MenuPage/drinkimgs/${row[9]?.value?.toString() ?? ''}';
                 
                
                List<String> drinkIngredients = [];

                for (int i = 10; i <= 12; i++) {
                  var cellValue = row[i]?.value?.toString().trim() ?? ' ';
                  if (cellValue.isNotEmpty && cellValue.toUpperCase() != "N/A") {
                    drinkIngredients.add(cellValue);
                  }
                }

                // Create the drink without specifying an ID
                Drink drink = Drink("", drinkName, drinkDescription, drinkPrice,
                    drinkAlcohol, drinkType, drinkIngredients, drinkImage, drinkStyle);
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

    String extractTagFromSheetName(String sheetName) {
    // Use the entire sheet name as the tag
    return sheetName;
  }

}
