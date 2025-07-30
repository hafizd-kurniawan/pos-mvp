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
    // Handle backend first_name/last_name to frontend name mapping
    final firstName = json['first_name']?.toString() ?? '';
    final lastName = json['last_name']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();
    
    return Customer(
      id: json['id']?.toString() ?? '',
      customerCode: json['customer_code']?.toString() ?? '',
      name: fullName.isNotEmpty ? fullName : json['name']?.toString() ?? 'Unknown Customer',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString(),
      identityType: json['identity_type']?.toString(),
      identityNumber: json['identity_number']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    // Split name back to first_name and last_name for backend compatibility
    final nameParts = name.trim().split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    
    return {
      'id': id,
      'customer_code': customerCode,
      'first_name': firstName,
      'last_name': lastName,
      'name': name, // Keep both for compatibility
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