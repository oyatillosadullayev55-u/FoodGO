enum UserRole {
  customer,
  courier,
  restaurant,
  admin;

  /// Noma'lum qiymat kelsa, eng kam huquqli rol (customer) beriladi.
  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
          (r) => r.name == value,
      orElse: () => UserRole.customer,
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.role,
    this.fullName,
    this.phone,
  });

  final String id;
  final UserRole role;
  final String? fullName;
  final String? phone;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      role: UserRole.fromString(map['role'] as String?),
      fullName: map['full_name'] as String?,
      phone: map['phone'] as String?,
    );
  }
}