import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';
import '../data/user_profile.dart';

final supabaseProvider = Provider<SupabaseClient>(
      (ref) => Supabase.instance.client,
);

final authRepositoryProvider = Provider<AuthRepository>(
      (ref) => AuthRepository(ref.watch(supabaseProvider)),
);

/// Serverdagi profil (rol shu yerdan olinadi).
final profileProvider = FutureProvider.autoDispose<UserProfile>(
      (ref) => ref.watch(authRepositoryProvider).fetchProfile(),
);