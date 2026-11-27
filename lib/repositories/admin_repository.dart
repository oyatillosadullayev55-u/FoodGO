import 'package:supabase_flutter/supabase_flutter.dart';

typedef DbRow = Map<String, dynamic>;

/// Super Admin amallari. Ruxsatni server (RLS va is_admin()) tekshiradi.
class AdminRepository {
  AdminRepository(this._client);

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<DbRow>> list(
    String table, {
    String select = '*',
    Map<String, Object> filters = const {},
    List<String> isNull = const [],
    required String orderBy,
    bool ascending = true,
    int limit = 500,
  }) {
    var request = _client.from(table).select(select);
    for (final f in filters.entries) {
      request = request.eq(f.key, f.value);
    }
    for (final column in isNull) {
      request = request.isFilter(column, null);
    }
    return request.order(orderBy, ascending: ascending).limit(limit);
  }

  Future<void> insert(String table, DbRow values) =>
      _client.from(table).insert(values);

  /// RLS rad etsa, Supabase xato bermaydi: o'zgargan qator sonini tekshiramiz.
  Future<void> update(String table, Object id, DbRow values) async {
    final rows = await _client
        .from(table)
        .update(values)
        .eq('id', id)
        .select('id');
    if (rows.isEmpty) throw Exception("Saqlab bo'lmadi: ruxsat yo'q");
  }

  Future<void> delete(String table, Object id) async {
    final rows = await _client.from(table).delete().eq('id', id).select('id');
    if (rows.isEmpty) throw Exception("O'chirib bo'lmadi: ruxsat yo'q");
  }

  Future<DbRow> analytics(int days) async {
    final data = await _client.rpc('admin_analytics', params: {'p_days': days});
    return Map<String, dynamic>.from(data as Map);
  }

  Future<List<DbRow>> fraudSignals() async {
    final data = await _client.rpc('fraud_signals');
    return [
      for (final row in data as List) Map<String, dynamic>.from(row as Map),
    ];
  }

  Future<List<DbRow>> users({String? role, String query = ''}) {
    var request = _client.from('profiles').select();
    if (role != null) request = request.eq('role', role);
    final text = query.replaceAll(RegExp(r'[%_,()*]'), ' ').trim();
    if (text.isNotEmpty) {
      request = request.or(
        'full_name.ilike.%$text%,email.ilike.%$text%,phone.ilike.%$text%',
      );
    }
    return request.order('full_name', ascending: true).limit(200);
  }

  /// Yopiq bucket'dagi hujjat uchun 5 daqiqalik havola.
  Future<String> documentUrl(String path) =>
      _client.storage.from('partner-docs').createSignedUrl(path, 300);
}
