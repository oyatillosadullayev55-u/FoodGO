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
