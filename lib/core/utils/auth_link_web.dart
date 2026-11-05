import 'dart:js_interop';

@JS('location.search')
external String get _search;

@JS('location.hash')
external String get _hash;

@JS('location.pathname')
external String get _pathname;

@JS('location.origin')
external String get _origin;

@JS('location.reload')
external void _reload();

@JS('history.replaceState')
external void _replaceState(JSAny? state, JSString unused, JSString url);

/// `Uri.base` brauzerda `document.baseURI` ni qaytaradi va u URL
/// fragmentini (`#...`) o'z ichiga olmaydi. Shuning uchun havola
/// parametrlari to'g'ridan-to'g'ri `location` dan o'qiladi.
Map<String, String> _params(String raw) {
  if (raw.isEmpty) return const {};
  final text = raw.startsWith('?') || raw.startsWith('#')
      ? raw.substring(1)
      : raw;
  if (text.isEmpty) return const {};
  try {
    return Uri.splitQueryString(text);
  } on FormatException {
    return const {};
  }
}

Map<String, String> _authParams() {
  final search = _params(_search);
  if (search.containsKey('error') ||
      search.containsKey('error_code') ||
      search.containsKey('type')) {
    return search;
  }
  final hash = _params(_hash);
  return hash.isNotEmpty ? hash : search;
}

bool isPasswordRecoveryLink() => _authParams()['type'] == 'recovery';

String? passwordRecoveryLinkError() {
  final params = _authParams();
  if (!params.containsKey('error') && !params.containsKey('error_code')) {
    return null;
  }
  return params['error_description'] ??
      params['error_code'] ??
      params['error'] ??
      'unknown';
}

/// Supabase havoladagi tokenni o'qib bo'lgach, manzil qatoridagi
/// auth parametrlarini tozalaydi — GoRouter ularni marshrut deb o'ylamaydi.
void cleanAuthLinkFromAddressBar() {
  final params = _authParams();
  final hasAuthParams =
      params.containsKey('access_token') ||
      params.containsKey('refresh_token') ||
      params.containsKey('type') ||
      params.containsKey('error') ||
      params.containsKey('error_code') ||
      params.containsKey('code');
  if (!hasAuthParams) return;

  final path = _pathname.isEmpty ? '/' : _pathname;
  _replaceState(null, ''.toJS, '$_origin$path'.toJS);
}

void reloadPage() {
  _reload();
}
