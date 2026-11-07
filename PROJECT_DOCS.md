# FoodGo Delivery App - Complete Project Documentation

FoodGo is a multi-role food delivery and marketplace platform built with **Flutter**, **Dart**, **Riverpod**, **GoRouter**, and **Supabase**.

---

## 🏗️ Architecture & User Roles

The application consists of 3 primary user roles:

1. **👑 Admin (Boshqaruvchi):**
   - Manages partner restaurants and cafes.
   - Can add new partner restaurants (Name, description, address, image URL, rating) directly to the Supabase database (`restaurants` table).
   - Can delete or manage existing partner listings.

2. **🍔 Hamkor / Restoran (Partner / Restaurant Owner):**
   - Selects their restaurant/cafe from the partner list.
   - Adds, updates, and manages menu items / dishes (Name, price, description, image URL) in the Supabase database (`products` table).
   - Receives and manages customer orders.

3. **👤 Mijoz (Customer):**
   - Browses restaurants and food categories.
   - Searches for dishes and restaurants.
   - Adds items to the cart and places orders.
   - Tracks order status live with preparation time and estimated delivery time.

---

## ⚡ Quick Testing / Role Switching

To facilitate rapid testing before enabling strict production authentication workflows, the login screen includes **Quick Role Selection Buttons**:
- 👑 **Admin**: Instantly navigates to the Admin Panel (`/admin`).
- 🍔 **Hamkor**: Instantly navigates to the Restaurant/Partner Panel (`/restaurant`).
- 👤 **Mijoz**: Instantly navigates to the Customer Home Screen (`/customer/home`).

---

## 🔐 Supabase Configuration & Password Recovery (6-digit OTP)

### 1. User Management (Deleting Accounts)
To delete test accounts in Supabase SQL Editor:
```sql
delete from auth.users
where email in ('test1@example.com', 'test2@example.com');

-- Or delete all except admin:
delete from auth.users
where email <> 'oyatillosadullayev55@gmail.com';
```

### 2. Emergency Password Reset (SQL Editor)
If you need to instantly set a new password for your admin account:
```sql
update auth.users
set encrypted_password = crypt('YangiParol-2026!', gen_salt('bf')),
    updated_at = now()
where email = 'oyatillosadullayev55@gmail.com';
```

### 3. Password Recovery Email Template (6-digit OTP)
In Supabase Dashboard → Authentication → Email Templates → Reset Password (or Emails → Templates):
- **Subject:** `FoodGo: parolni tiklash`
- **Body (HTML):**
  ```html
  <h2>Parolni tiklash</h2>
  <p>Parolni yangilash uchun ilovaga quyidagi 6 xonali kodni kiriting:</p>
  <h1>{{ .Token }}</h1>
  <p>Kod 1 soat ichida amal qiladi. Agar siz so'ramagan bo'lsangiz, bu xatni e'tiborsiz qoldiring.</p>
  ```

### 4. SMTP Settings (Gmail)
To prevent rate-limiting with Supabase's default email service, configure SMTP in Supabase Dashboard → Authentication → Emails → SMTP Settings:
- **Host:** `smtp.gmail.com`
- **Port:** `465`
- **Username:** Your Gmail address
- **Password:** 16-digit Google App Password (`myaccount.google.com/apppasswords`)
- **Sender email:** Your Gmail address
- **Sender name:** `FoodGo`

---

## 🛠️ Tech Stack

- **Frontend:** Flutter, Material 3, Riverpod (State Management)
- **Routing:** GoRouter (Declarative navigation & shell routes)
- **Backend & Database:** Supabase (Auth, PostgreSQL database, Realtime)
- **Design System:** Clean, modern UI inspired by top food delivery platforms.

---

## 🚀 Cloud Deployment & Web Build

- The app supports cross-platform deployment (Android, iOS, Web).
- Production web build can be generated using:
  ```bash
  flutter build web
  ```
- Output files are located in `build/web/` ready for cloud hosting (Vercel, Netlify, Render, or GitHub Pages).
