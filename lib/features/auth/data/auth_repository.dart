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

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Rol serverdagi `profiles.role` dan olinadi — mijoz uni o'zgartira olmaydi.
  Future<UserProfile> fetchProfile() async {
    final user = _client.auth.currentUser;
    final uid = user?.id;
    final email = user?.email?.toLowerCase();

    if (uid == null) {
      return const UserProfile(
        id: 'guest_user',
        role: UserRole.customer,
        fullName: 'Mehmon',
      );
    }

    Map<String, dynamic>? data;
    try {
      data = await _client
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();
    } catch (_) {
      // Profil hali yaratilmagan bo'lsa, pastdagi zaxira qiymat ishlatiladi.
    }

    var ownsRestaurant = false;
    if (email != null && email.isNotEmpty) {
      try {
        final rows = await _client
            .from('restaurants')
            .select('id')
            .eq('owner_email', email)
            .limit(1);
        ownsRestaurant = rows.isNotEmpty;
      } catch (_) {}
    }

    return UserProfile(
      id: uid,
      role: data == null
          ? UserRole.customer
          : UserRole.fromString(data['role'] as String?),
      fullName: data?['full_name'] as String? ??
          user?.userMetadata?['full_name'] as String?,
      phone: data?['phone'] as String? ??
          user?.userMetadata?['phone'] as String?,
      email: data?['email'] as String? ?? email,
      ownsRestaurant: ownsRestaurant,
    );
  }
}
