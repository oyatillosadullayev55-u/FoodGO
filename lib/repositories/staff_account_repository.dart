import 'package:supabase_flutter/supabase_flutter.dart';

class StaffAccountException implements Exception {
  StaffAccountException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Xodim akkaunti turlari.
const staffRoles = ['restaurant', 'shop', 'master', 'courier'];

/// Ro'yxatdagi bitta xodim (hamkor).
class StaffMember {
  const StaffMember({
    required this.id,
    required this.role,
    this.fullName,
    this.email,
    this.phone,
  });

  final String id;
  final String role; // [staffRoles] dan biri
  final String? fullName;
  final String? email;
  final String? phone;

  String get title {
    final n = fullName?.trim();
    if (n != null && n.isNotEmpty) return n;
    return email ?? id;
  }

  factory StaffMember.fromMap(Map<String, dynamic> m) => StaffMember(
        id: m['id'] as String,
        role: (m['role'] as String?) ?? '',
        fullName: m['full_name'] as String?,
        email: m['email'] as String?,
        phone: m['phone'] as String?,
      );
}

class StaffAccountRepository {
  StaffAccountRepository(this._client);

  final SupabaseClient _client;

  Future<List<StaffMember>> list() async {
    try {
      final rows = await _client
          .from('profiles')
          .select('id, role, full_name, email, phone')
          .inFilter('role', staffRoles)
          .order('full_name');
      return (rows as List)
          .map((e) => StaffMember.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      throw StaffAccountException("Ro'yxatni yuklab bo'lmadi.");
    }
  }

  /// Restoran va magazin uchun [restaurantName] (do'kon nomi), usta uchun
  /// [fullName] shart.
  Future<void> create({
    required String email,
    required String password,
    required String role,
    String? fullName,
    String? phone,
    String? restaurantName,
  }) {
    return _invoke({
      'action': 'create',
      'email': email.trim().toLowerCase(),
      'password': password,
      'role': role,
      if (fullName != null && fullName.trim().isNotEmpty)
        'full_name': fullName.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (restaurantName != null && restaurantName.trim().isNotEmpty)
        'restaurant_name': restaurantName.trim(),
    });
  }

  Future<void> remove(String userId) =>
      _invoke({'action': 'remove', 'user_id': userId});

  Future<void> _invoke(Map<String, dynamic> body) async {
    try {
      await _client.functions.invoke('admin-create-user', body: body);
    } on FunctionException catch (e) {
      final d = e.details;
      final msg = (d is Map && d['error'] is String)
          ? d['error'] as String
          : 'Server xatosi (${e.status})';
      throw StaffAccountException(msg);
    } catch (_) {
      throw StaffAccountException(
          "Server bilan aloqa yo'q. Internetni tekshiring.");
    }
  }
}
