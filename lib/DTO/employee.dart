

class Employee {
  int? employeeId;
  int? merchantId;
  String? name;
  String? image;
  String? email;

  Employee({
    this.employeeId,
    this.merchantId,
    this.name,
    this.image,
    this.email,
  });

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        employeeId: json['employeeId'] as int?,
        merchantId: json['merchantId'] as int?,
        name: json['name'] as String?,
        image: json['image'] as String?,
        email: json['email'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'merchantId': merchantId,
        'name': name,
        'image': image,
        'email': email,
      };
}