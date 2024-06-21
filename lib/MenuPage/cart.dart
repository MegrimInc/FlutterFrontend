import 'package:barzzy_app1/Backend/drink.dart';

class Cart {
  final List<String> _drinkIds = [];

  List<String> get drinkIds => List.unmodifiable(_drinkIds);

  void addDrink(String drinkId) {
    _drinkIds.add(drinkId);
    print('Drink with ID $drinkId added to the cart.');
  }

  void removeDrink(String drinkId) {
    if (_drinkIds.contains(drinkId)) {
      _drinkIds.remove(drinkId);
      print('Drink with ID $drinkId removed from the cart.');
    } else {
      print('Drink with ID $drinkId not found in the cart.');
    }
  }

  void clearCart() {
    _drinkIds.clear();
  }



}
