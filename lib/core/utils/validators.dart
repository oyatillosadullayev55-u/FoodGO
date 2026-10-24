class Validators {
  static String? name(String? v) {
    if ((v ?? '').trim().length < 2) return 'Ismingizni kiriting';
    return null;
  }

  static String? phone(String? v) {
    final t = (v ?? '').replaceAll(RegExp(r'[\s\-()]'), '');
    if (t.isEmpty) return 'Telefon raqamini kiriting';
    if (!RegExp(r'^\+?\d{9,15}$').hasMatch(t)) {
      return "Telefon raqami noto'g'ri";
    }
    return null;
  }

  static String? email(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Emailni kiriting';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) {
      return "Email noto'g'ri";
    }
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Parolni kiriting';
    if (v.length < 6) return "Parol kamida 6 ta belgi bo'lsin";
    return null;
  }

  /// "+998 90 123-45-67" -> "+998901234567"
  static String cleanPhone(String v) =>
      v.replaceAll(RegExp(r'[\s\-()]'), '');
}