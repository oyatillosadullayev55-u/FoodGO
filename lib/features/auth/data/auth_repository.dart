import 'package:supabase_flutter/supabase_flutter.dart';

import 'user_profile.dart';

/// Ro'yxatdan o'tish natijasi.
enum SignUpStatus {
  /// Sessiya ochildi — foydalanuvchi darhol tizimga kirdi.
  signedIn,

  /// Hisob yaratildi, lekin Supabase email tasdiqlashni talab qilmoqda.
  needsConfirmation,

  /// Bu email allaqachon ro'yxatdan o'tgan, parol esa mos kelmadi.
  emailTaken,
}

class SignUpResult {
  const SignUpResult(this.status);

  final SignUpStatus status;
}

enum _SignInAttempt { ok, unconfirmed, rejected }

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;

  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    AuthResponse res;
    try {
      res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone},
      );
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('already registered')) {
        return _resolveExistingAccount(email, password);
      }
      rethrow;
    }

    if (res.session != null) {
      return const SignUpResult(SignUpStatus.signedIn);
    }

    // Supabase email mavjudligini yashirish uchun bo'sh identities qaytaradi.
    final exists = res.user?.identities?.isEmpty ?? false;

    switch (await _trySignIn(email, password)) {
      case _SignInAttempt.ok:
        return const SignUpResult(SignUpStatus.signedIn);
      case _SignInAttempt.unconfirmed:
        return const SignUpResult(SignUpStatus.needsConfirmation);
      case _SignInAttempt.rejected:
        return SignUpResult(
          exists ? SignUpStatus.emailTaken : SignUpStatus.needsConfirmation,
        );
    }
  }

  Future<SignUpResult> _resolveExistingAccount(
    String email,
    String password,
  ) async {
    switch (await _trySignIn(email, password)) {
      case _SignInAttempt.ok:
        return const SignUpResult(SignUpStatus.signedIn);
      case _SignInAttempt.unconfirmed:
        return const SignUpResult(SignUpStatus.needsConfirmation);
      case _SignInAttempt.rejected:
        return const SignUpResult(SignUpStatus.emailTaken);
    }
  }

  Future<_SignInAttempt> _trySignIn(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return _SignInAttempt.ok;
    } on AuthException catch (e) {
      final m = e.message.toLowerCase();
      if (m.contains('email not confirmed') ||
          m.contains('email not verified') ||
          m.contains('not confirmed')) {
        return _SignInAttempt.unconfirmed;
      }
      return _SignInAttempt.rejected;
    }
  }

  Future<void> resendConfirmation(String email) async {
    await _client.auth.resend(email: email, type: OtpType.signup);
  }

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> resetPassword(String email) async {
    final base = Uri.base;
    final isHttp = base.scheme == 'http' || base.scheme == 'https';
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: isHttp ? '${base.origin}/' : null,
    );
  }

  /// Emailga yuborilgan 6 xonali kodni tekshiradi va sessiya ochadi.
  /// Havolani ochish imkoni bo'lmaganda (masalan, telefonda) ishlatiladi.
  Future<void> verifyRecoveryCode({
    required String email,
    required String code,
  }) async {
    await _client.auth.verifyOTP(
      type: OtpType.recovery,
      email: email,
      token: code.trim(),
    );
  }

  /// Tiklash havolasidan kelgan sessiya uchun yangi parol o'rnatadi.
  Future<void> updatePassword(String password) async {
    await _client.auth.updateUser(UserAttributes(password: password));
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
      fullName:
          data?['full_name'] as String? ??
          user?.userMetadata?['full_name'] as String?,
      phone:
          data?['phone'] as String? ?? user?.userMetadata?['phone'] as String?,
      email: data?['email'] as String? ?? email,
      ownsRestaurant: ownsRestaurant,
    );
  }
}
