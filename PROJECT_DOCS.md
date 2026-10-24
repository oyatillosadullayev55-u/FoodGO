# FoodGo Delivery App - Project Documentation

FoodGo is a modern multi-role food delivery and marketplace platform built with **Flutter**, **Dart**, **Riverpod**, **GoRouter**, and **Supabase**.

## Architecture & Roles

The application consists of 3 main user roles:

1. **Admin (Boshqaruvchi):**
   - Manages partner restaurants and cafes.
   - Can add new partner restaurants (Name, description, address, image URL, rating) directly to the database.
   - Can delete or manage existing partner listings.

2. **Hamkor / Restoran (Partner / Restaurant Owner):**
   - Selects their restaurant/cafe from the partner list.
   - Adds, updates, and manages menu items / dishes (Name, price, description, image URL).
   - Receives and manages customer orders.

3. **Mijoz (Customer):**
   - Browses restaurants and food categories.
   - Searches for dishes and restaurants.
   - Adds items to the cart and places orders.
   - Tracks order status live with preparation time and estimated delivery time.

---

## Quick Testing / Role Switching

To facilitate rapid testing before enabling strict authentication workflows, the login screen includes **Quick Role Selection Buttons**:
- 👑 **Admin**: Instantly navigates to the Admin Panel (`/admin`).
- 🍔 **Hamkor**: Instantly navigates to the Restaurant/Partner Panel (`/restaurant`).
- 👤 **Mijoz**: Instantly navigates to the Customer Home Screen (`/customer/home`).

---

## Tech Stack

- **Frontend:** Flutter, Material 3, Riverpod (State Management)
- **Routing:** GoRouter (Declarative navigation & shell routes)
- **Backend & Database:** Supabase (Auth, PostgreSQL database, Realtime)
- **Design System:** Clean, modern UI inspired by top food delivery platforms.
