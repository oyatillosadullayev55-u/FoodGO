---
name: osongo-feature
description: OsonGo Flutter ilovasiga yangi ekran, funksiya, model, repository, provider yoki route qo'shganda va mavjud UI'ni o'zgartirganda ishlating. Use when adding or changing a screen or feature in this Flutter app.
---

# OsonGo'da yangi funksiya qo'shish

Bitta kod bazasi, uchta ilova: **mijoz**, **hamkor**, **admin**
(`lib/main_*.dart`). Stack: Flutter, Riverpod 3, GoRouter, Supabase.

Avval funksiya qaysi ilovaga tegishli ekanini aniqlang, so'ng eng o'xshash
mavjud sahifani o'qib, o'sha uslubni takrorlang.

## Tartib

1. **Model** — `lib/models/`. `const` konstruktor, `final` maydonlar,
   `factory X.fromMap(Map<String, dynamic> map)`. Bazadagi ustunlar
   `snake_case`. Sonlar: `(map['price'] as num).toInt()`. Pul `int` (so'm).
2. **Repository** — `lib/repositories/` (auth uchun
   `lib/features/auth/data/`). `SupabaseClient` konstruktor orqali beriladi.
   Sahifa va providerlar Supabase'ga to'g'ridan-to'g'ri so'rov yubormaydi.
3. **Provider** — tegishli `features/.../*_providers.dart`.
   - Client: `ref.watch(supabaseProvider)`.
   - O'qish: `FutureProvider.autoDispose` (kerak bo'lsa `.family`).
   - Jonli ma'lumot: repository'da `liveQuery` (`core/utils/live_query.dart`),
     providerda `StreamProvider.autoDispose`.
   - `await` dan keyin notifier holatini o'zgartirishdan oldin `ref.mounted`.
4. **Sahifa** — `lib/features/<rol yoki bo'lim>/`.
5. **Route** — yo'l nomini `core/router/app_router.dart` dagi `AppRoutes` ga
   yozing, sahifani faqat kerakli ilovaning `core/router/routes_*.dart`
   faylida bog'lang. Ilova boshqa ilovaning sahifalarini import qilmasin.
6. **Test** — pastdagi bo'lim.

## Server qoidalari

- Narx, komissiya va ruxsat serverda hisoblanadi. Buyurtmada faqat mahsulot
  id va miqdori yuboriladi.
- Buyurtma va xizmat holati faqat RPC orqali o'zgaradi
  (masalan `set_order_status`).
- Ilovadagi rol tekshiruvi faqat qulaylik uchun; himoya RLS'da.
- Baza o'zgarsa, `osongo-supabase` skilliga o'ting.

## UI

- Tayyor widgetlar: `core/widgets/ui.dart` (`SoftCard`, `SectionHeader`,
  `ChipsBar`, `AppImage`, `PromoBanner`, `StatusPill`, `StatTile`,
  `AdaptiveGrid`, `RatingLine`). Yangisini yozishdan oldin shularni tekshiring.
- Yuklanish va xato: `AsyncValueView` (`onRetry` bilan); katalog sahifalarida
  `CatalogScaffold` va `CatalogSection`.
- Keng ekran: `ContentFrame`.
- Ranglar `AppColors` dan. Tungi rejimni `Theme.of(context).brightness` bilan
  hisobga oling.
- Pul: `formatSom()` (`core/utils/money.dart`).
- Xato matni: `friendlyError(e)`. Yangi jadval hali bazada bo'lmasligi mumkin
  bo'lsa, `isMissingSchema(e)` ni hisobga oling.
- Ko'rinadigan matn va kod izohlari **o'zbek tilida**. Apostrofli matnni
  qo'sh tirnoqda yozing: `"Do'konlar"`.
- Ekran 320 px kenglikda ham overflow bermasin.

## Test

- Yangi asosiy ekranni `test/screens_test.dart` yoki
  `test/screens_more_test.dart` ga qo'shing.
- Yangi providerni testda `overrides` orqali almashtiring; namunaviy ma'lumot
  `test/support/demo_data.dart` da. Testlar haqiqiy serverga ulanmaydi.
- Ekranni `pumpScreen` bilan chizing, `expect(tester.takeException(), isNull)`
  bilan tekshiring va `closeScreen` bilan yoping.

Ish tugagach `osongo-check` skillini bajaring.
