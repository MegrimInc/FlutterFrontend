
import 'dart:convert';
import 'package:megrim/DTO/employee.dart';

class Merchant {
  int? merchantId;
  String? name;
  String? city;
  String? zipCode;
  String? address;
  String? stateOrProvince;
  String? country;
  String? nickname;
  String? image;
  Map<String, String?>? discountSchedule;
  List<Employee>? employees;

  

  Merchant(
      {
      this.merchantId,
      this.name,
      this.city,
      this.zipCode,
      this.address,
      this.stateOrProvince,
      this.country,
      this.nickname,
      this.image,
      this.discountSchedule,
      this.employees,
      }
      );

  
  //GETTER METHODS

  String? getName() {
    return name;
  }

  String? getNickname() {
    return nickname;
  }

  // JSON serialization to support saving and loading merchant data
  Map<String, dynamic> toJson() {
    return {
     'merchantId': merchantId,
      'name': name,
      'city': city,
      'zipCode': zipCode,
      'address': address,
      'stateOrProvince': stateOrProvince,
      'country': country,
      'nickname': nickname,
      'image': image,
      'discountSchedule': discountSchedule, 
       'employees': employees?.map((e) => e.toJson()).toList(),
    };
  }

  // Factory Constructor (fromJson)
  factory Merchant.fromJson(Map<String, dynamic> json) {
    return Merchant(
      merchantId: json['merchantId'] as int?, // Match toJson key
      name: json['name'] as String?,
      city: json['city'] as String?,
      zipCode: json['zipCode'] as String?,
      address: json['address'] as String?,
      stateOrProvince: json['stateOrProvince'] as String?,
      country: json['country'] as String?,
      nickname: json['nickname'] as String?, // Match toJson key
      image: json['image'] as String?, // Match toJson key
      discountSchedule: json['discountSchedule'] != null
          ? (json['discountSchedule'] is String
              ? Map<String, String?>.from(jsonDecode(json['discountSchedule']))
              : Map<String, String?>.from(json['discountSchedule']))
          : null,
       employees: (json['employees'] as List<dynamic>?)
            ?.map((e) => Employee.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
  }
}