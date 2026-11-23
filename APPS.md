# OsonGo — 3 ta ilova (bitta kod bazasi)

| Ilova | Kim uchun | Kirish nuqtasi | Android ID |
|---|---|---|---|
| OsonGo | Mijozlar (ro'yxatdan o'tish ochiq) | `lib/main_customer.dart` | uz.osongo.app |
| OsonGo Hamkor | Restoran egalari va kuryerlar | `lib/main_partner.dart` | uz.osongo.partner |
| OsonGo Admin | Administrator (faqat xodim qo'shish/chiqarish) | `lib/main_admin.dart` | uz.osongo.admin |

Hisoblarni admin yaratadi (email + parol beradi). O'zi ro'yxatdan o'tgan — mijoz.
Noto'g'ri ilovaga kirgan hisobga "bu hisob boshqa ilovaga tegishli" ko'rsatiladi.

## Ishga tushirish
```
flutter run --flavor customer -t lib/main_customer.dart
flutter run --flavor partner  -t lib/main_partner.dart
flutter run --flavor admin    -t lib/main_admin.dart
flutter run -d chrome -t lib/main_admin.dart      # admin veb-panel
```
## APK
```
flutter build apk --release --flavor customer -t lib/main_customer.dart \
  --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```
(CI uchala APK ni avtomatik yig'adi.)

## Supabase
Edge Function: `supabase functions deploy admin-create-user`
(service-role kalitini ilovaga yoki repoga qo'ymang — funksiyada avtomatik bor).

## Hali qilinmagan
iOS flavorlari, Firebase (push) har ilova uchun alohida sozlamasi.

## O'zgarishlar (3 ilovaga bo'lish)
- `lib/main_customer.dart`, `main_partner.dart`, `main_admin.dart` — alohida kirish nuqtalari; `lib/main.dart` mijoz ilovasini ishga tushiradi.
- `lib/bootstrap.dart` — umumiy ishga tushirish; `lib/core/config/app_flavor.dart` — qaysi hisob qaysi ilovaga kirishi.
- `lib/core/router/routes_*.dart` — har ilovaning o'z sahifalari.
- `lib/features/admin/admin_people_page.dart` — admin: xodim qo'shish/chiqarish.
- `supabase/functions/admin-create-user` — hisob yaratish/o'chirish (faqat admin chaqira oladi).
- Eski `admin_home_page.dart`, `admin_providers.dart`, `admin_repository.dart` endi ishlatilmaydi (o'chirish mumkin).
