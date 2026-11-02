# 🍔 FoodGo Delivery — Oziq-ovqat va Taom Yetkazib Berish Ekotizimi

[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![State Management](https://img.shields.io/badge/State-Riverpod-0553B1)](https://riverpod.dev)
[![Backend](https://img.shields.io/badge/Backend-Supabase-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20Web%20%7C%20iOS-4CAF50)](https://flutter.dev)

**FoodGo** — bu zamonaviy, tezkor va ko'p funksiyali taom yetkazib berish platformasi. Loyiha ham **Web sayt**, ham **Android smartfonlar (APK)** uchun to'liq moslashuvchan (responsive) arxitekturada yaratilgan bo'lib, uchta asosiy foydalanuvchi roli — **Mijoz (Customer)**, **Restoran Egasi (Owner)** va **Tizim Administratori (Admin)** imkoniyatlarini o'z ichiga oladi.

---

## 📌 Asosiy Xususiyatlar

- 🚀 **To'liq 3 Rolli Ekotizim**: Bitta ilovada Mijoz, Restoran Egasi va Admin rollari ajratilgan.
- ⚡ **Tezkor va To'siqsiz Kirish**: Ro'yxatdan o'tishdagi murakkab to'siqlarsiz, to'g'ridan-to'g'ri o'z rolingizni tanlab tizimga kirish imkoniyati.
- 🔄 **Tezkor Rol Almashtirgich (`_RoleSwitcherBar`)**: Har qanday sahifaning tepasida 1-chertish orqali Mijoz, Restoran va Admin interfeyslariga o'tish imkoniyati.
- 📱 **Web va Mobil (APK) Moslashuvchanligi**: `ContentFrame` orqali keng ekranli monitorlarda ham, tor smartfon ekranlarida ham ideal markazlashgan va qulay UI.
- 🖼️ **Aqlli Taom Rasmlari Tizimi (`FoodImages`)**: Tarmoqdagi xatoliklar yoki bo'sh rasm havolalarida avtomatik ravishda mos Unsplash CDN taom rasmlarini yuklash (Osh, Somsa, Shashlik, Burger, Pitsa, Sushi, Qahva va h.k.).
- 🎨 **Mavzular**: Tungi (Dark) va Kunduzgi (Light) rejimlarni qo'llab-quvvatlash.
- 📍 **Jonli Xarita va Buyurtma Holati**: `flutter_map` orqali kuryer va restoran joylashuvi, buyurtma statusini jonli kuzatish.

---

## 👥 Foydalanuvchi Rollari (Roles)

```
                     ┌────────────────────────┐
                     │   FoodGo Ekotizimi     │
                     └───────────┬────────────┘
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
         ▼                       ▼                       ▼
┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│   👤 MIJOZ       │    │   🍳 OWNER       │    │   🛡️ ADMIN       │
│  (Customer)      │    │  (Restoran egasi)│    │  (Administrator) │
├──────────────────┤    ├──────────────────┤    ├──────────────────┤
│• Katalog & Izlash│    │• Restoranni      │    │• Yangi restoran  │
│• Savatcha (Cart) │    │  boshqarish      │    │  hamkor qo'shish │
│• Buyurtma berish │    │• Taom qo'shish/  │    │• Restoranlarni   │
│• Jonli kuzatuv   │    │  tahrirlash/     │    │  monitoring va   │
│• Profil & Sozlama│    │  o'chirish       │    │  o'chirish       │
│                  │    │• Buyurtma holati-│    │• Tizim umumiy    │
│                  │    │  ni yangilash    │    │  statistikalari  │
└──────────────────┘    └──────────────────┘    └──────────────────┘
```

### 1. 👤 Mijoz (Customer)
* **Asosiy sahifa**: Jonli bannerlar, ommabop restoranlar (Osh Markazi, Burger House va b.), toifalar (Milliy, Burger, Pitsa, Fastfood, Qahva).
* **Qidiruv va Saralash**: Taom yoki muassasa nomi bo'yicha bir zumda izlash.
* **Savatcha va To'lov**: Taomlarni bir nechtadan qo'shish, promokod kiritish, to'lov usulini tanlash (*Naqd pul*, *FoodGo Pay*, *Bank kartasi*).
* **Buyurtmalar**: O'tgan va joriy buyurtmalarni ko'rish, kuryer harakatini bosqichma-bosqich kuzatish (*Qabul qilindi* → *Tayyorlanmoqda* → *Yetkazilmoqda* → *Yetkazildi*).
* **Profil**: Yetkazib berish manzillari, sevimlilar, FoodGo Plus obunasi va ilova sozlamalari.

### 2. 🍳 Restoran Egasi (Owner)
* **Restoran tanlash**: O'z muassasasi (masalan, *Osh Markazi*, *Burger House*) profilini tanlab ish yuritish.
* **Menyu boshqaruvi**: Yangi taomlar qo'shish (nomi, tavsifi, narxi, rasm URL'i, toifasi).
* **Taomlarni tahrirlash/o'chirish**: Narxlarni o'zgartirish yoki mavjud bo'lmagan taomlarni menyudan olib tashlash.
* **Buyurtmalar nazorati**: Oshxonaga tushgan buyurtmalarni real vaqt rejimida qabul qilish va ularning holatini bosqichma-bosqich yangilash.

### 3. 🛡️ Tizim Administratori (Admin)
* **Hamkor restoranlar boshqaruvi**: Yangi restoranlarni ro'yxatdan o'tkazish (nomi, manzili, rasmi, o'rtacha reytingi, ish vaqti).
* **Katalog nazorati**: Faoliyatini to'xtatgan yoki talabga javob bermaydigan restoranlarni o'chirish.
* **Platforma monitoringi**: Platformadagi barcha umumiy ko'rsatkichlarni bir joyda kuzatish.

---

## 🛠️ Texnologiyalar Steki

| Qism | Texnologiya |
|---|---|
| **Dasturlash tili** | Dart 3.13+ |
| **Freymvork** | Flutter 3.47+ (Null-safety, Material 3) |
| **State Management** | Riverpod 2.x (`flutter_riverpod`) |
| **Navigatsiya & Routing** | GoRouter (`go_router`) |
| **Backend & MB** | Supabase (PostgreSQL, Realtime, Supabase Auth) |
| **Kesh & Rasmlar** | CachedNetworkImage, Unsplash CDN Fallback |
| **Xarita** | Flutter Map (`flutter_map`, LatLong2, OpenStreetMap) |
| **Platformalar** | Web (HTML5/CanvasKit), Android (APK), iOS |

---

## 📁 Loyiha Strukturasi

```
foodgo/
├── android/                 # Android loyiha konfiguratsiyasi va build fayllari
├── ios/                     # iOS loyiha fayllari
├── web/                     # Web sayt uchun index.html, manifest va sozlamalar
├── supabase/
│   └── seed_demo.sql        # Demo ma'lumotlar bazasi va jadvallar skripti
└── lib/
    ├── app.dart             # Ilovaning kirish nuqtasi va asosiy MaterialApp
    ├── main.dart            # Flutter ilovani ishga tushiruvchi main()
    ├── core/                # Umumiy xizmatlar va yordamchilar
    │   ├── constants/       # Ilova doimiylari
    │   ├── router/          # GoRouter marshrutlari va sahifalar bog'lanishi
    │   ├── theme/           # AppColors, AppTheme (Yorug' va Tungi mavzu)
    │   ├── utils/           # Formatlash, Valyuta (so'm), FoodImages aqlli rasmlar
    │   └── widgets/         # ContentFrame (Web/APK responsive konteyner), umumiy UI
    ├── features/            # Alohida funksional modullar
    │   ├── admin/           # Admin paneli (Restoran qo'shish/o'chirish)
    │   ├── auth/            # Kirish sahifasi va rollar selektori
    │   ├── customer/        # Mijoz interfeysi (Home, Search, Cart, Checkout, Orders, Profile)
    │   ├── restaurant/      # Restoran egasi interfeysi (Menu & Buyurtma boshqaruvi)
    │   └── splash/          # Splash ochilish ekrani
    ├── models/              # DTO va ma'lumotlar modellari (Restoran, Mahsulot, Buyurtma)
    └── repositories/        # Supabase bilan ma'lumot almashish omborlari
```

---

## 🚀 O'rnatish va Ishga Tushirish

### 1. Repozitoriyani klonlash
```bash
git clone https://github.com/oyatillosadullayev55-u/FoodGO.git
cd FoodGO
```

### 2. Bog'liqliklarni o'rnatish
```bash
flutter pub get
```

### 3. Supabase ma'lumotlar bazasini tayyorlash (Ixtiyoriy)
Agar o'z shaxsiy Supabase ma'lumotlar bazangizni ulamoqchi bo'lsangiz:
1. [supabase.com](https://supabase.com) orqali yangi loyiha oching.
2. `supabase/seed_demo.sql` fayli ichidagi barcha SQL so'rovlarini **SQL Editor** bo'limiga tashlab, **Run** tugmasini bosing.
3. Loyihangizning `URL` va `ANON_KEY` parametrlarini oling.

---

## 💻 Dasturni Ishga Tushirish

### Web brauzerda ishga tushirish (Chrome / Edge):
```bash
flutter run -d chrome
```

### Android qurilmada yoki Emulyatorda ishga tushirish:
```bash
flutter run
```

### Supabase ma'lumotlari bilan ishga tushirish:
```bash
flutter run -d chrome --dart-define=SUPABASE_URL="SIZNING_SUPABASE_URL" --dart-define=SUPABASE_ANON_KEY="SIZNING_ANON_KEY"
```

---

## 📦 Loyihani Build Qilish (Web va APK)

### 🌐 1. Web sayt uchun to'liq yig'ish (Production Web):
```bash
flutter build web --release
```
*Yaratilgan fayllar joyi:* `build/web/`  
*Ushbu papkadagi fayllarni to'g'ridan-to'g'ri Firebase Hosting, Vercel, Netlify yoki har qanday web hostingga joylashtirishingiz mumkin.*

### 📱 2. Android APK yaratish (O'rnatish uchun tayyor fayl):
```bash
# Debug APK yaratish:
flutter build apk --debug

# Yoki to'liq optimallashgan Release APK:
flutter build apk --release
```
*Yaratilgan tayyor APK fayl joyi:*  
`build/app/outputs/flutter-apk/app-debug.apk` (yoki `app-release.apk`)

---

## 🌟 Rollarni Sinab Ko'rish Qo'llanmasi

1. Dasturni ishga tushiring.
2. Kirish sahifasida kerakli rolni bosing:
   - **Mijoz sifatida kirish** — To'g'ridan-to'g'ri taom buyurtma qilish interfeysi ochiladi.
   - **Restoran Egasi sifatida kirish** — Menyu va taomlarni boshqarish paneli ochiladi.
   - **Admin sifatida kirish** — Restoranlarni qo'shish va nazorat qilish paneli ochiladi.
3. Istalgan paytda sahifaning eng yuqori qismidagi tezkor paneldan boshqa rolga 1-chertish bilan o'tishingiz mumkin!

---

## 👨‍💻 Muallif

- **Muallif:** Oyatillo
- **GitHub:** [@oyatillosadullayev55-u](https://github.com/oyatillosadullayev55-u)
- **Email:** oyatillosadullayev55@gmail.com

---

## 📄 Litsenziya

Ushbu loyiha ochiq manbali bo'lib, ta'lim va tijoriy maqsadlarda foydalanish uchun taqdim etiladi.
