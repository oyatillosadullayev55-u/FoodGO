# FoodGO 🍔

A Flutter food delivery app: browse restaurants, add dishes to the cart, check out and track orders.

## ✨ Features

- Onboarding, splash and authentication flow with **Supabase**
- Role-based entry point for different user types
- Restaurant catalog, food categories and search
- Restaurant menus, product details and quantity stepper
- Cart, checkout and order history with order details
- Profile and saved preferences
- Light and dark themes
- Map support with `flutter_map`

## 🛠️ Tech stack

Flutter · Dart · Riverpod · go_router · Supabase · cached_network_image · flutter_map

## 📂 Structure

```
lib/
├── core/           # constants, router, theme, shared widgets
├── features/       # auth, customer, cart, checkout, orders
├── models/         # restaurant, product, cart item, order
└── repositories/   # catalog, menu and orders repositories
```

## 🚀 Getting started

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

Supabase credentials are passed with `--dart-define` and are not stored in the repository.

## 📌 Status

In development — more features are on the way.
