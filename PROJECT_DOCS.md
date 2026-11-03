# FoodGo Delivery — Project Documentation

FoodGo is a multi-role food delivery platform built with Flutter, Riverpod,
GoRouter and Supabase. Full setup instructions (in Uzbek) live in
[README.md](README.md).

## Roles (4)

| Role | Route | Description |
|---|---|---|
| Admin | `/admin` | Creates/edits/deletes restaurants, picks coordinates on a map, assigns the owner email, manages user roles, monitors all orders and statistics. Only accounts whose email is listed as admin in `supabase/roles_setup.sql` can enter. |
| Restaurant owner | `/restaurant` | Manages only the restaurant whose `owner_email` matches their login email: menu CRUD and order status transitions. |
| Courier | `/courier` | Claims `ready_for_pickup` orders via `claim_order`, then moves them through `picked_up` → `on_the_way` → `delivered`. |
| Customer | `/customer/home` | Browses the catalog, searches, builds a cart, pins the delivery location on a map, places orders (RPC `create_order`) and tracks status. |

## Order lifecycle

`pending → accepted → preparing → ready_for_pickup → courier_assigned →
picked_up → on_the_way → delivered`

Cancellation rules are enforced server-side by `set_order_status`:
customers may cancel only `pending`/`accepted`; owners may reject/cancel
orders that are not finished; couriers may only advance their assigned
orders.

## Security model

- Roles are stored in `profiles.role`. Clients cannot escalate their role:
  only admins can update `profiles`.
- RLS is enabled on `profiles`, `restaurants`, `products`, `categories`,
  `orders`, `order_items` and `couriers`; policies are defined in
  `supabase/roles_setup.sql`.
- Restaurant ownership is matched by `owner_email` against the JWT email
  (plus optional `owner_id`).
- Order creation and status changes go through security-definer RPCs.
- There is no role-switch UI; `RoleGuard` blocks direct navigation to panels
  that do not match the user's role.

## Setup summary

1. Run `supabase/seed_demo.sql` in the Supabase SQL Editor (demo data).
2. Run `supabase/roles_setup.sql` (roles, RLS, RPCs). Edit the admin email
   list in that file first if needed.
3. Start the app with `--dart-define=SUPABASE_URL=...` and
   `--dart-define=SUPABASE_ANON_KEY=...`.
4. Log in with the admin account; the role gate redirects to `/admin`.

## Maps

`lib/core/widgets/app_map.dart` wraps `flutter_map` with CARTO Voyager tiles
and OpenStreetMap attribution. It is used for:

- admin restaurant location picker (tap to place the pin),
- restaurant page location card,
- checkout delivery pin,
- customer order detail (restaurant + destination),
- owner and courier order cards.

## Main code

```
lib/core/router/app_router.dart          role-based routes and guards
lib/core/widgets/role_guard.dart         panel access control
lib/repositories/admin_repository.dart   admin operations
lib/repositories/delivery_repository.dart owner + courier operations
lib/repositories/orders_repository.dart  customer orders
lib/features/admin/                      admin panel (restaurants/users/orders)
lib/features/courier/                    courier panel
lib/features/restaurant/                 owner panel
lib/features/customer/                   customer app
supabase/roles_setup.sql                 schema additions, RLS, RPCs
supabase/seed_demo.sql                   demo catalog with coordinates
```

## Build

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL="https://<project-ref>.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="<anon-key>"
```

Output: `build/web/`. Android: `flutter build apk --release` with the same
`--dart-define` flags.
