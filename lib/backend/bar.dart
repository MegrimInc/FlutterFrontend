
class Bar {
  String? id;
  String? name;
  String? address;
  String? tag;
  String? tagimg;
  String? barimg;
  String? openhours;
   Map<String, String?>? happyHours;
  

  Bar(
      {
      this.id,
      this.name,
      this.address,
      this.tag,
      this.tagimg,
      this.barimg,
      this.openhours,
      this.happyHours,
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
     'id': id,
      'name': name,
      'address': address,
      'barTag': tag,
      'tagImage': tagimg,
      'barImage': barimg,
      'openHours': openhours,
      'happyHours': happyHours,
      
    };
  }

  // Factory constructor for creating an instance from JSON
  factory Bar.fromJson(Map<String, dynamic> json) {
    return Bar(
      id: (json['id'] ?? json['barId'])?.toString(),
      name: json['name'] as String?,
      address: json['address'] as String?,
      tag: json['barTag'] as String?,
      tagimg: json['tagImage'] as String?,
      barimg: json['barImage'] as String?,
      openhours: json['openHours'] as String?,
      happyHours: json['happyHours'] != null
          ? Map<String, String?>.from(json['happyHours'])
          : null, // Deserialize happy hours map
    );
  }


}
