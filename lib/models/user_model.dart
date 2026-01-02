class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String role;
  final bool isActive;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.role,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'],
      role: json['role'] ?? 'customer',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'role': role,
      'isActive': isActive,
    };
  }
}

