class Customer {
  final String id;
  final String customerCode;
  final String name;
  final String email;
  final String phone;
  final String? address;
  final String? identityType;
  final String? identityNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.customerCode,
    required this.name,
    required this.email,
    required this.phone,
    this.address,
    this.identityType,
    this.identityNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      customerCode: json['customer_code'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      identityType: json['identity_type'],
      identityNumber: json['identity_number'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_code': customerCode,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'identity_type': identityType,
      'identity_number': identityNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Customer(id: $id, code: $customerCode, name: $name, phone: $phone)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}