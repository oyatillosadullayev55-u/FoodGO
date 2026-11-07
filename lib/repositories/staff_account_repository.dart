import 'package:supabase_flutter/supabase_flutter.dart';

class StaffAccountException implements Exception {
  StaffAccountException(this.message);
  final String message;
  @override
  String toString() => message;
}

class StaffAccountRepository {
  StaffAccountRepository(this._client);

  final SupabaseClient _client;

  /// role: 'restaurant' yoki 'courier'
  Future<void> create({
    required String email,
    required String password,
    required String role,
    String? fullName,
    String? phone,
  }) {
    return _invoke({
      'action': 'create',
      'email': email.trim().toLowerCase(),
      'password': password,
      'role': role,
      if (fullName != null && fullName.trim().isNotEmpty)
        'full_name': fullName.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    });
  }

  Future<void> setPassword({
    required String userId,
    required String password,
  }) {
    return _invoke({
      'action': 'set_password',
      'user_id': userId,
      'password': password,
    });
  }

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
      throw StaffAccountException('Server bilan aloqa yo\'q. Internetni tekshiring.');
    }
  }
}
