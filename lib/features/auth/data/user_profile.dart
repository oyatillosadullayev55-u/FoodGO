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

  String get label => switch (this) {
    UserRole.customer => 'Mijoz',
    UserRole.courier => 'Kuryer',
    UserRole.restaurant => 'Restoran egasi',
    UserRole.admin => 'Administrator',
  };
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.role,
    this.fullName,
    this.phone,
    this.email,
    this.ownsRestaurant = false,
  });

  final String id;
  final UserRole role;
  final String? fullName;
  final String? phone;
  final String? email;
  final bool ownsRestaurant;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      role: UserRole.fromString(map['role'] as String?),
      fullName: map['full_name'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
    );
  }
}
