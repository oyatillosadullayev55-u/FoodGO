# Kirish, ro'yxatdan o'tish va email sozlamalari

## Ro'yxatdan o'tish va kirish

- Ro'yxatdan o'tishda ism, telefon, email va parol (ikki marta) kiritiladi.
  Yangi hisob har doim **Mijoz** roli bilan yaratiladi.
- Email allaqachon ro'yxatdan o'tgan bo'lsa, ilova shu email va parol bilan
  kirishga urinadi; parol mos kelmasa **Parolni tiklash** taklif qilinadi.
- Supabase'da *Confirm email* yoqilgan bo'lsa, foydalanuvchi avval emailidagi
  havolani bosishi kerak. Ilova buni aniqlab, **Qayta yuborish** tugmasini
  beradi. Tasdiqlashsiz ro'yxatdan o'tish uchun: Dashboard →
  **Authentication → Sign In / Providers → Email → Confirm email** ni o'chiring.
- Restoran, magazin, usta va kuryer hisoblarini faqat admin yaratadi
  (**Super Admin → Xodimlar**).

## Parolni tiklash

Login sahifasidagi **Parolni unutdingizmi?** havolasi tiklash xatini yuboradi.
Havola ochilmasa (masalan, `localhost` manzili telefonda ishlamaydi), shu
sahifada **email + 6 xonali kod + yangi parol** bilan tiklash mumkin.

Kod xatda ko'rinishi uchun Dashboard → **Authentication → Email Templates →
Reset Password** andozasiga `{{ .Token }}` qo'shing:

```html
<h2>Parolni tiklash</h2>
<p>Parolni yangilash uchun ilovaga quyidagi 6 xonali kodni kiriting:</p>
<h1>{{ .Token }}</h1>
<p>Yoki havolani bosing: <a href="{{ .ConfirmationURL }}">Parolni tiklash</a></p>
```

Havola to'g'ri ochilishi uchun **Authentication → URL Configuration** bo'limida
**Site URL** va **Redirect URLs** ga ilova manzilini qo'shing (masalan,
`http://127.0.0.1:8088` va hosting domeningiz). Havolani telefonda ochish uchun
ilovani LAN manzilida ishga tushiring:

```bash
flutter run -d chrome -t lib/main_customer.dart --web-hostname 0.0.0.0 --web-port 8088
```

## SMTP

Supabase'ning standart email xizmatida soatiga bir nechta xat cheklovi bor;
tez-tez so'rov yuborilsa `Error sending recovery email` qaytadi. Doimiy yechim:
Dashboard → **Settings → Authentication → SMTP** bo'limida o'z SMTP'ingizni
sozlash (masalan Gmail: `smtp.gmail.com`, port 465, 16 xonali App Password).
