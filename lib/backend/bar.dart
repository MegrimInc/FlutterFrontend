
class Bar {
  String? id;
  String? name;
  String? address;
  String? tag;
  String? tagimg;
  String? barimg;
  String? openhours;
  

  Bar(
      {
      this.id,
      this.name,
      this.address,
      this.tag,
      this.tagimg,
      this.barimg,
      this.openhours
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
      'openHours': openhours
      
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
      openhours: json['openHours'] as String?,
    );
  }


}
