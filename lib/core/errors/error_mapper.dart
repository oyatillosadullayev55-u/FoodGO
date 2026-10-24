import 'package:supabase_flutter/supabase_flutter.dart';

String friendlyError(Object error) {
  if (error is AuthException) {
    final m = error.message.toLowerCase();
    if (m.contains('invalid login credentials')) {
      return "Email yoki parol noto'g'ri. Agar parolni unutgan bo'lsangiz, 'Parolni unutdingizmi?' tugmasidan foydalaning.";
    }
    if (m.contains('already registered') || m.contains('already been registered')) {
      return 'Bu email bilan hisob allaqachon mavjud. Iltimos, tizimga kiring yoki parolni tiklang.';
    }
    if (m.contains('password') && m.contains('characters')) {
      return "Parol kamida 6 ta belgidan iborat bo'lsin";
    }
    if (m.contains('email not confirmed')) {
      return 'Emailingiz hali tasdiqlanmagan. Iltimos, emailingizni tekshiring.';
    }
    if (m.contains('rate limit') || m.contains('too many')) {
      return "Juda ko'p urinish. Birozdan keyin qayta urinib ko'ring";
    }
    return error.message.isNotEmpty ? error.message : 'Kirishda xatolik yuz berdi';
  }
  if (error is PostgrestException) {
    // Serverdagi raise exception xabarlari (o'zbekcha) shu kod bilan keladi.
    if (error.code == 'P0001') return error.message;
    return error.message.isNotEmpty ? error.message : "Ma'lumotlarni olishda xatolik yuz berdi";
  }
  final text = error.toString().toLowerCase();
  if (text.contains('socketexception') ||
      text.contains('failed host lookup') ||
      text.contains('clientexception')) {
    return "Internet bilan aloqa yo'q";
  }
  return 'Kutilmagan xatolik yuz berdi';
}