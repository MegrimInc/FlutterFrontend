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

}
