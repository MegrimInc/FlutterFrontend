
import 'dart:convert';

class Bar {
  String? id;
  String? name;
  String? city;
  String? zipCode;
  String? address;
  String? stateOrProvince;
  String? country;
  String? tag;
  String? tagimg;
  String? barimg;
  bool? open;
  Map<String, String?>? happyHours;
  int? bonus;
  

  Bar(
      {
      this.id,
      this.name,
      this.city,
      this.zipCode,
      this.address,
      this.stateOrProvince,
      this.country,
      this.tag,
      this.tagimg,
      this.barimg,
      this.open,
      this.happyHours,
      this.bonus
      }
      );

  
  //GETTER METHODS

  String? getName() {
    return name;
  }

  String? gettag() {
    return tag;
  }

  // JSON serialization to support saving and loading bar data
  Map<String, dynamic> toJson() {
    return {
     'merchantId': id,
      'name': name,
      'city': city,
      'zipCode': zipCode,
      'address': address,
      'stateOrProvince': stateOrProvince,
      'country': country,
      'nickname': tag,
      'logoImage': tagimg,
      'storeImage': barimg,
      'openHours': open,
      'discountSchedule': happyHours,
      'bonus': bonus,
      
    };
  }

  // Factory Constructor (fromJson)
  factory Bar.fromJson(Map<String, dynamic> json) {
    return Bar(
      id: json['merchantId']?.toString(), // Match toJson key
      name: json['name'] as String?,
      city: json['city'] as String?,
      zipCode: json['zipCode'] as String?,
      address: json['address'] as String?,
      stateOrProvince: json['stateOrProvince'] as String?,
      country: json['country'] as String?,
      tag: json['nickname'] as String?, // Match toJson key
      tagimg: json['logoImage'] as String?, // Match toJson key
      barimg: json['storeImage'] as String?, // Match toJson key
      happyHours: json['discountSchedule'] != null
          ? (json['discountSchedule'] is String
              ? Map<String, String?>.from(jsonDecode(json['discountSchedule']))
              : Map<String, String?>.from(json['discountSchedule']))
          : null,
      bonus: json['bonus'] as int?,
    );
  }
}


