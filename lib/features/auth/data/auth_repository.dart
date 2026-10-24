import 'package:supabase_flutter/supabase_flutter.dart';

import 'user_profile.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;

  /// true qaytsa, foydalanuvchi darhol tizimga kirdi.
  /// false bo'lsa, email tasdiqlash kerak.
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'phone': phone},
    );
    return res.session != null;
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<UserProfile> fetchProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw AuthException('Tizimga kirilmagan');
    }
    final data =
    await _client.from('profiles').select().eq('id', uid).single();
    return UserProfile.fromMap(data);
  }
}