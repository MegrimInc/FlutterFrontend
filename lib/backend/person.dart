import 'package:uuid/uuid.dart';

class Person {
  String? first, last, middle, birthdate;
  Uuid personUUID = const Uuid();

  bool changeUUID (Uuid newUUID) {
    if(personUUID != newUUID) {
      personUUID = newUUID;
      return true;
    }

    return false;
  }

  

     //GETTER&SETTER METHODS
  void setFirstName(String newField) {
    first = newField;
    }

  void setLastName(String newField) {
    last = newField;
  }

  void setMiddleName(String newField) {
    middle = newField;
  }

  void setBirthdate(String newField) {
    birthdate = newField;
  }

  void setPersonUUID(Uuid newField) {
    personUUID = newField;
  }




  String? getFirstName() {
      return first;
    }

  String? getLastName() {
    return last;
  }

  String? getMiddleName() {
    return middle;
  }

  String? getBirthdate() {
    return birthdate;
  }

  Uuid getPersonUUID() {
    return personUUID;
  }

/*
  // JSON serialization to support saving and loading bar data
  Map<String, dynamic> toJson() {
    return {
      'drinks': drinks?.map((d) => d.toJson()).toList(),
      'name': name,
      'address': address,
      'tag': tag,
      'nameAndTagMap': nameAndTagMap?.map((key, value) => MapEntry(key, value)),
    };
  }

  // Factory constructor for creating an instance from JSON
  factory Bar.fromJson(Map<String, dynamic> json) {
    var drinksList = json['drinks'] as List?;
    List<Drink>? drinks =
        drinksList?.map((item) => Drink.fromJson(item)).toList();
    // Extract nameAndTagMap from JSON
    var nameAndTagMapJson = json['nameAndTagMap'] as Map<String, dynamic>?;
    Map<String, List<String>>? nameAndTagMap;
    if (nameAndTagMapJson != null) {
      nameAndTagMap = nameAndTagMapJson.map((key, value) {
        if (value is List) {
          return MapEntry(key, value.cast<String>());
        }
        return MapEntry(key, []);
      });
    }

    return Bar(
      drinks: drinks,
      name: json['name'] as String?,
      address: json['address'] as String?,
      tag: json['tag'] as String?,
      nameAndTagMap: nameAndTagMap,
    );
  }
*/




}
