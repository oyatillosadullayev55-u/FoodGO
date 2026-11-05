import 'package:supabase_flutter/supabase_flutter.dart';

String friendlyError(Object error) {
  if (error is AuthException) {
    final m = error.message.toLowerCase();
    if (m.contains('invalid login credentials')) {
      return "Email yoki parol noto'g'ri. Yaqinda ro'yxatdan o'tgan bo'lsangiz, "
          "avval emailingizni tasdiqlang yoki 'Parolni unutdingizmi?' orqali "
          "parolni tiklang.";
    }
    if (m.contains('already registered') ||
        m.contains('already been registered')) {
      return 'Bu email bilan hisob allaqachon mavjud. Iltimos, tizimga kiring yoki parolni tiklang.';
    }
    if (m.contains('should be different')) {
      return 'Yangi parol eskisidan farq qilishi kerak';
    }
    if (m.contains('password') && m.contains('characters')) {
      return "Parol kamida 6 ta belgidan iborat bo'lsin";
    }
    if (m.contains('weak password') || m.contains('password is too weak')) {
      return "Parol juda oddiy. Harflar va raqamlardan iborat murakkabroq "
          "parol o'rnating.";
    }
    if (m.contains('auth session missing') || m.contains('session missing')) {
      return "Sessiya topilmadi. Parolni tiklash havolasini qaytadan oling.";
    }
    if (m.contains('expired') || m.contains('invalid token')) {
      return "Havola eskirgan yoki yaroqsiz. Yangi tiklash havolasini oling.";
    }
    if (m.contains('email not confirmed') ||
        m.contains('email not verified') ||
        m.contains('not confirmed')) {
      return 'Emailingiz hali tasdiqlanmagan. Emailingizga yuborilgan havolani '
          'bosing yoki tasdiqlash xatini qayta yuboring.';
    }
    if (m.contains('database error saving new user')) {
      return "Ro'yxatdan o'tishda baza xatosi yuz berdi. Supabase'da "
          'supabase/roles_setup.sql ishga tushirilganini tekshiring.';
    }
    if (m.contains('signups not allowed') || m.contains('signup is disabled')) {
      return "Ro'yxatdan o'tish vaqtincha o'chirilgan. Supabase Auth "
          'sozlamalarida Email provider yoqilganini tekshiring.';
    }
    if (m.contains('email rate limit') ||
        m.contains('over_email_send_rate_limit')) {
      return "Email yuborish cheklovi tugdi. Supabase'ning standart email "
          'xizmatida soatiga bir nechta xat yuboriladi — birozdan keyin qayta '
          "urinib ko'ring yoki Dashboard'da shaxsiy SMTP sozlang.";
    }
    if (m.contains('unexpected_failure') ||
        m.contains('error sending') ||
        m.contains('recovery email')) {
      return "Tiklash xati yuborilmadi — Supabase'ning standart email "
          "xizmatida cheklov yoki vaqtinchalik muammo bor. 15–30 daqiqa "
          "kutib qayta urinib ko'ring. Doimiy yechim: Supabase Dashboard → "
          "Settings → Authentication → SMTP bo'limida o'z Gmail/SendGrid "
          'SMTP manzilini sozlang.';
    }
    if (m.contains('email sending') || m.contains('smtp')) {
      return "Email yuborish sozlanmagan. Supabase Dashboard → "
          'Authentication → Emails/SMTP bo\'limini tekshiring.';
    }
    if (m.contains('redirect') &&
        (m.contains('not allowed') || m.contains('invalid'))) {
      return 'Tiklash havolasi uchun ruxsat berilmagan manzil. Supabase → '
          'Authentication → URL Configuration bo\'limida Site URL va Redirect '
          "URLs ga ilova manzilini qo'shing.";
    }
    if (m.contains('security purposes') || m.contains('only request this')) {
      final sec = RegExp(r'after (\d+) seconds?').firstMatch(m)?.group(1);
      return sec == null
          ? "Xavfsizlik uchun birozdan keyin qayta urinib ko'ring."
          : 'Xavfsizlik uchun $sec soniyadan keyin qayta yuborish mumkin.';
    }
    if (m.contains('user not found')) {
      return "Bu email bilan hisob topilmadi. Avval ro'yxatdan o'ting.";
    }
    if (m.contains('unable to validate email') || m.contains('invalid email')) {
      return "Email manzil noto'g'ri kiritilgan.";
    }
    if (m.contains('rate limit') || m.contains('too many')) {
      return "Juda ko'p urinish. Birozdan keyin qayta urinib ko'ring";
    }
    return error.message.isNotEmpty
        ? error.message
        : 'Kirishda xatolik yuz berdi';
  }
  if (error is PostgrestException) {
    // Serverdagi raise exception xabarlari (o'zbekcha) shu kod bilan keladi.
    if (error.code == 'P0001') return error.message;
    return error.message.isNotEmpty
        ? error.message
        : "Ma'lumotlarni olishda xatolik yuz berdi";
  }
  final text = error.toString().toLowerCase();
  if (text.contains('socketexception') ||
      text.contains('failed host lookup') ||
      text.contains('clientexception')) {
    return "Internet bilan aloqa yo'q";
  }
  return 'Kutilmagan xatolik yuz berdi';
}
