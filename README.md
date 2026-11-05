# FoodGo — Taom yetkazib berish tizimi (4 rol)

FoodGo — Flutter + Supabase asosida qurilgan taom yetkazib berish platformasi.
Tizimda to'rt rol bor: **Admin**, **Restoran egasi**, **Kuryer** va **Mijoz**.
Rollar serverda (`profiles.role`) saqlanadi; mijoz ilovadan rol tanlab
admin bo'lib kira olmaydi. Admin paneli faqat SQL skriptda ko'rsatilgan
admin emailiga ega hisob uchun ochiladi.

## Rollar va imkoniyatlar

| Rol | Panel manzili | Asosiy imkoniyatlar |
|---|---|---|
| Admin | `/admin` | Restoran qo'shish/tahrirlash/o'chirish, xaritada joylashuv belgilash, egasi emailini biriktirish, foydalanuvchi rollarini boshqarish, barcha buyurtmalar va statistika |
| Restoran egasi | `/restaurant` | O'z restorani menyusi (qo'shish/tahrirlash/o'chirish), o'z buyurtmalarini qabul qilish va holatini yangilash |
| Kuryer | `/courier` | Tayyor buyurtmalarni olish, "olib ketdim" → "yo'lda" → "yetkazildi" bosqichlari, xaritada manzillar |
| Mijoz | `/customer/home` | Restoranlar katalogi, qidiruv, savat, manzilni xaritada belgilash, buyurtma berish, holatni kuzatish |

Buyurtma holatlari zanjiri:

```
pending → accepted → preparing → ready_for_pickup
        → courier_assigned → picked_up → on_the_way → delivered
```

Bekor qilish: mijoz faqat `pending`/`accepted` bosqichida, restoran esa
yakunlanmagan buyurtmani `rejected`/`cancelled` qilishi mumkin.

## Birinchi ishga tushirish (majburiy qadam)

### 1. Supabase SQL skriptlarini ishga tushirish

Supabase Dashboard → **SQL Editor** → **New query**.

1. `supabase/seed_demo.sql` — demo restoranlar, kategoriyalar va taomlar
   (ixtiyoriy, lekin sinash uchun tavsiya etiladi).
2. `supabase/roles_setup.sql` — **majburiy**: rollar, RLS siyosatlari,
   `set_order_status` va `claim_order` funksiyalari, demo egaliklar.

Tartib muhim: avval `seed_demo.sql`, keyin `roles_setup.sql`.

`roles_setup.sql` boshidagi admin emailini o'zingizga moslang:

```sql
when lower(u.email) in ('oyatillosadullayev55@gmail.com', 'admin@foodgo.uz') then 'admin'
```

Bu satr faylning ikki joyida uchraydi (profil yaratish triggeri va demo
rollarni biriktirish). Agar boshqa email bilan admin bo'lmoqchi bo'lsangiz,
ikkalasini ham o'zgartiring va skriptni qayta ishga tushiring.

Tekshirish:

```sql
select id, email, role from public.profiles order by role, email;
select name, owner_email, is_active, lat, lng from public.restaurants;
```

### 2. Ilovani ishga tushirish

```bash
flutter pub get

flutter run -d chrome \
  --dart-define=SUPABASE_URL="https://<project-ref>.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="<anon-key>"
```

Android qurilmada:

```bash
flutter run \
  --dart-define=SUPABASE_URL="https://<project-ref>.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="<anon-key>"
```

### 3. Admin sifatida kirish

1. `/login` sahifasiga o'ting.
2. SQL skriptda admin qilib belgilangan email va parol bilan kiring.
3. Tizim profildagi rolni o'qib, avtomatik `/admin` paneliga yo'naltiradi.
4. Boshqa foydalanuvchi `/admin` manzilini ochsa, "Ruxsat yo'q" ekrani
   chiqadi — bu RLS va rol himoyasi bilan ham tekshiriladi.

## Admin: yangi restoran qo'shish

1. **Admin panel → Restoranlar → Restoran qo'shish**.
2. Nom, tavsif, manzil va egasi emailini kiriting.
3. Xaritani bosib restoranning aniq nuqtasini belgilang
   (koordinatalar pastda ko'rinadi).
4. **Qo'shish** — restoran `is_active = true` bilan saqlanadi va mijozlar
   katalogida darhol ko'rinadi (mijoz sahifasini yangilash kifoya).
5. **Faol** switch orqali restoranni vaqtincha yopish mumkin — yopilgan
   restoran mijozlarga ko'rinmaydi.

Egasi emailiga ro'yxatdan o'tgan foydalanuvchi biriktirilsa, uning profili
avtomatik `restaurant` roliga o'tadi (agar u allaqachon ro'yxatdan o'tgan
bo'lsa). Shu email bilan kirgan foydalanuvchi `/restaurant` panelida faqat
o'z restoranini ko'radi.

## Restoran egasi

1. Admin panelida restoran yaratilganda **Egasi (email)** maydoniga
   o'z hisobingiz emailini kiriting.
2. Shu email bilan `/login` orqali kiring — tizim `/restaurant` paneliga
   yo'naltiradi.
3. **Menyu** bo'limida taom qo'shing (nom, narx, tavsif, rasm URL).
4. **Buyurtmalar** bo'limida yangi buyurtmani tasdiqlang, tayyorlang va
   "Tayyor" deb belgilang. Shundan keyin buyurtma kuryerlarga ko'rinadi.

## Kuryer

Kuryer hisobini admin **Foydalanuvchilar** bo'limida `Kuryer` rolini berish
orqali tayinlaydi. Kuryer panelida:

- **Yangi buyurtmalar** — restoran "Tayyor" qilgan va hali biriktirilmagan
  buyurtmalar. **Buyurtmani olish** tugmasi buyurtmani kuryerga biriktiradi.
- **Mening yetkazmalarim** — biriktirilgan buyurtmalar va bosqichlar:
  olib ketdim → yo'lda → yetkazildi.
- Har bir kartada restoran va mijoz manzili xaritada ko'rsatiladi.

## Mijoz va xarita

- Restoran sahifasida restoranning aniq joylashuvi xaritada chiqadi.
- Checkout sahifasida xaritani bosib uy joylashuvini belgilash mumkin;
  koordinatalar buyurtmaga saqlanadi va kuryer/karta ko'rinishida ishlatiladi.
- Buyurtma tafsilotlarida restoran va yetkazish nuqtasi xaritada ko'rinadi.
- Buyurtma berish uchun tizimga kirish talab qilinadi. Mehmon foydalanuvchi
  katalogni ko'ra oladi, lekin checkoutda kirish taklif qilinadi.

## Ro'yxatdan o'tish va kirish

- Ro'yxatdan o'tishda ism, telefon, email va parol (ikki marta) kiritiladi.
  Yangi hisob har doim **Mijoz** roli bilan yaratiladi.
- Ro'yxatdan o'tgach, ilova **"Qaysi sahifaga o'tamiz?"** deb so'raydi:
  Bosh sahifa, Buyurtmalarim, Savatcha yoki Profil. Admin/restoran/kuryer
  paneli faqat shu rolga ega hisoblarga taklif qilinadi.
- Agar email allaqachon ro'yxatdan o'tgan bo'lsa, ilova shu email va parol
  bilan kirishga urinadi; parol mos kelmasa **"Parolni tiklash"** taklif
  qilinadi. Qayta ro'yxatdan o'tishga urinish shart emas.
- **Muhim:** Supabase'da *Confirm email* yoqilgan bo'lsa, hisob yaratilgach
  foydalanuvchi avval emailidagi havolani bosishi kerak. Ilova buni aniqlab,
  "Emailingizni tasdiqlang" oynasida **Qayta yuborish** tugmasini beradi.
  Tezkor (tasdiqlashsiz) ro'yxatdan o'tish uchun Supabase Dashboard →
  **Authentication → Sign In / Providers → Email → Confirm email** ni o'chirib
  saqlang.
- Login sahifasida **"Parolni unutdingizmi?"** havolasi bor — u parolni
  tiklash xatini yuboradi.

## Xavfsizlik

- Rol faqat `profiles.role` dan olinadi; mijoz uni o'zgartira olmaydi.
- Barcha jadvallarda RLS yoqilgan:
  - mijoz faqat o'z buyurtmalarini ko'radi;
  - restoran egasi faqat o'z restorani va buyurtmalarini ko'radi;
  - kuryer tayyor buyurtmalarni va o'ziga biriktirilganlarni ko'radi;
  - admin hammasini ko'radi.
- Buyurtma holati to'g'ridan-to'g'ri `update` bilan emas, `set_order_status`
  RPC orqali o'zgartiriladi; funksiya rolni va ruxsat etilgan o'tishlarni
  serverda tekshiradi.
- Kuryer buyurtmani `claim_order` RPC orqali oladi (poyga holatida ikkinchi
  kuryer biriktira olmaydi).
- Admin/restoran/kuryer hisoblari faqat admin tomonidan beriladi; login
  sahifasida rol tanlash tugmalari yo'q.

## Loyiha strukturasi (asosiy fayllar)

```
lib/
├── core/
│   ├── router/app_router.dart          # Marshrutlar va RoleGuard
│   ├── widgets/app_map.dart            # flutter_map xarita komponenti
│   └── widgets/role_guard.dart         # Rol bo'yicha kirish himoyasi
├── features/
│   ├── admin/                          # Admin panel (3 tab + xarita editor)
│   ├── courier/courier_home_page.dart  # Kuryer paneli
│   ├── restaurant/restaurant_home_page.dart
│   ├── customer/                       # Mijoz: home, checkout, orders va h.k.
│   └── auth/                           # Login, register, role gate
├── models/                             # Restaurant, Product, FoodOrder
└── repositories/
    ├── admin_repository.dart
    ├── delivery_repository.dart        # Owner + courier so'rovlari
    └── orders_repository.dart

supabase/
├── seed_demo.sql                       # Demo katalog va koordinatalar
└── roles_setup.sql                     # Rollar, RLS, RPC, demo egaliklar
```

## Build va hosting

Web (production):

```bash
flutter build web --release --no-web-resources-cdn \
  --dart-define=SUPABASE_URL="https://<project-ref>.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="<anon-key>"
```

`--no-web-resources-cdn` CanvasKit'ni Google CDN o'rniga `build/web/canvaskit/`
ichidan yuklaydi — ilova tezroq ochiladi va tashqi CDN'ga bog'liq bo'lmaydi.

Natija: `build/web/`. Papkani Firebase Hosting, Vercel, Netlify yoki oddiy
statik serverga joylashtirish mumkin. Lokal tekshirish:

```bash
cd build/web
python -m http.server 8088
```

Brauzerda `http://127.0.0.1:8088` oching.

Android APK:

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL="https://<project-ref>.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="<anon-key>"
```

## Demo hisoblar

`roles_setup.sql` quyidagi demo hisoblarni tayyorlaydi (parollar repo'da
saqlanmaydi; ular yaratilganda alohida belgilangan):

| Email | Rol | Izoh |
|---|---|---|
| `owner.foodgo@example.com` | restaurant | `Osh Markazi` restorani egasi |
| `courier.foodgo@example.com` | courier | Demo kuryer |
| `customer.foodgo@example.com` | customer | Demo mijoz |

Parolni bilmasangiz, Supabase Dashboard → **Authentication → Users**
bo'limida foydalanuvchini tanlab parolni yangilang yoki yangi hisob
yaratib, admin panelidan unga rol bering.

## Tez-tez uchraydigan muammolar

- **Admin panelda "Ruxsat yo'q"** — `roles_setup.sql` ishga tushirilmagan
  yoki sizning emailingiz admin ro'yxatida emas. SQL'dagi emailni
  tekshiring va skriptni qayta ishga tushiring.
- **Restoranlar katalogda ko'rinmaydi** — restoran `is_active = false`
  bo'lishi mumkin yoki SQL skript ishga tushirilmagan. Admin panelidan
  **Faol** switchini tekshiring.
- **Restoran paneli bo'sh** — admin panelidagi restoranning **Egasi
  (email)** maydoni sizning login emailingiz bilan bir xil emas.
- **Xarita bo'sh** — internet aloqasi yoki CARTO/OpenStreetMap tile'lariga
  kirish cheklangan. Xarita OpenStreetMap ma'lumotlaridan foydalanadi.
- **Kuryerga buyurtma ko'rinmaydi** — buyurtma hali `ready_for_pickup`
  holatiga o'tmagan yoki boshqa kuryerga biriktirilgan.

## Muallif

- **Oyatillo** — [@oyatillosadullayev55-u](https://github.com/oyatillosadullayev55-u)
- Email: oyatillosadullayev55@gmail.com

## Litsenziya

Ta'lim va tijoriy maqsadlarda foydalanish uchun taqdim etiladi.
