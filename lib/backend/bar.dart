
import 'package:barzzy_app1/Backend/order.dart';

class Bar {
  String? id;
  String? name;
  String? address;
  String? tag;
  String? tagimg;
  String? barimg;

  Bar(
      {
      this.id,
      this.name,
      this.address,
      this.tag,
      this.tagimg,
      this.barimg
      }
      );

  //  void addDrink(Drink drink) {
  //   drinks ??= <String, Drink>{};
  //   drinks![drink.id] = drink;
  // }
  //GETTER METHODS

  String? getName() {
    return name;
  }



  String? gettag() {
    return tag;
  }

  //  // Method to get a drink object by its ID
  // Drink getDrinkById(String id) {
  //   return drinks![id]!;
  // }

  // JSON serialization to support saving and loading bar data
  Map<String, dynamic> toJson() {
    return {
     'id': id,
      'name': name,
      'address': address,
      'barTag': tag,
      'tagImage': tagimg,
      'barImage': barimg,
    };
  }

  // Factory constructor for creating an instance from JSON
  factory Bar.fromJson(Map<String, dynamic> json) {
    return Bar(
      id: json['id']?.toString(),
      name: json['name'] as String?,
      address: json['address'] as String?,
      tag: json['barTag'] as String?,
      tagimg: json['tagImage'] as String?,
      barimg: json['barImage'] as String?,
    );
  }


}
