---
name: osongo-check
description: OsonGo'da o'zgarishlarni tekshirish, testlarni yurgizish, ilovani ishga tushirish yoki APK yig'ish kerak bo'lganda ishlating. Use before saying work is done, and to run or build the customer, partner and admin apps.
---

# OsonGo: tekshirish, ishga tushirish, yig'ish

## Tekshiruv (loyiha ildizidan)

```bash
flutter analyze
flutter test
```

Ikkalasi ham toza o'tishi kerak. Xato bo'lsa, natijasini ayting; testni
o'chirib yoki lintni `ignore` qilib yashirmang.

`supabase/` o'zgargan bo'lsa:

```bash
cd tool/sql_test
npm install    # birinchi marta
npm test
```

SQL testlari xotiradagi Postgres'da ishlaydi, haqiqiy Supabase'ga ulanmaydi.
O'tkazib yuborilgan bo'lsa, buni aytib o'ting.

UI o'zgargan bo'lsa, skrinshot olib ko'ring (`build/screenshots/`):

```bash
flutter test --dart-define=SCREENSHOTS=true
```

## Ishga tushirish

```bash
# Veb
flutter run -d chrome -t lib/main_customer.dart
flutter run -d chrome -t lib/main_partner.dart
flutter run -d chrome -t lib/main_admin.dart

# Android
flutter run --flavor customer -t lib/main_customer.dart
flutter run --flavor partner  -t lib/main_partner.dart
flutter run --flavor admin    -t lib/main_admin.dart
```

O'z Supabase loyihasi uchun `env.example.json` dan `env.json` yarating va
`--dart-define-from-file=env.json` qo'shing. `env.json`, `key.properties` va
keystore fayllari gitga kirmaydi.

## APK

```bash
flutter build apk --release --flavor customer -t lib/main_customer.dart
```

`partner` va `admin` uchun flavor va `-t` ni birga almashtiring.
iOS flavorlari sozlanmagan.

CI sozlamasi: `.github/workflows/ci.yml`.
