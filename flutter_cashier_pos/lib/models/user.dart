class User {
  final String id;
  final String username;
  final String email;
  final String name;
  final String role;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Combine first_name and last_name into name (handle nulls)
    final firstName = json['first_name']?.toString() ?? '';
    final lastName = json['last_name']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();
    
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: fullName.isNotEmpty ? fullName : json['username']?.toString() ?? 'Unknown User',
      role: json['role']?.toString() ?? 'cashier',
      isActive: json['is_active'] ?? true,
      lastLogin: json['last_login_at'] != null 
          ? DateTime.tryParse(json['last_login_at'].toString())
          : json['last_login'] != null 
          ? DateTime.tryParse(json['last_login'].toString())
          : null,
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
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'is_active': isActive,
      'last_login_at': lastLogin?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get roleDisplayName {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'manager':
        return 'Manager';
      case 'salesperson':
        return 'Sales Person';
      case 'mechanic':
        return 'Mechanic';
      case 'cashier':
        return 'Cashier';
      default:
        return role;
    }
  }

  bool get isCashier => role == 'cashier';
  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager';
  bool get isMechanic => role == 'mechanic';

  @override
  String toString() {
    return 'User(id: $id, username: $username, name: $name, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}