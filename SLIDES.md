# FoodGo Delivery Platform — Project Presentation

---

## Slide 1: Title & Overview
### **FoodGo: Modern Multi-Role Food Delivery & Marketplace**
- **Tech Stack:** Flutter (Cross-platform), Riverpod, GoRouter, Supabase (Auth, PostgreSQL, Realtime, Storage, Edge Functions).
- **Core Concept:** A complete, production-grade food delivery ecosystem connecting **Admins**, **Restaurant Partners**, **Couriers**, and **Customers**.

---

## Slide 2: Architecture & User Roles
### **3-Tier Role-Based Ecosystem**
1. **👑 Admin:** Manages system users (Restaurant owners & Couriers) securely via Edge Functions.
2. **🍔 Restaurant Partner:** Manages restaurant profile, active status, menu items, categories, and receives real-time orders.
3. **🚴 Courier:** Views available orders nearby, accepts deliveries, tracks live route with Geolocator and map navigation.
4. **👤 Customer:** Browses restaurants, manages persistent shopping cart, places orders with map coordinates, and tracks live status.

---

## Slide 3: Admin Panel & Security
### **Secure Staff & Partner Management**
- **Restricted Access:** Admin only manages staff accounts (Restaurant owners and Couriers).
- **Edge Functions (`admin-create-user`):** Server-side user creation with secure password generation and role assignment.
- **Partner Initialization:** Creating a restaurant partner automatically provisions an inactive restaurant profile (`is_active = false`), ensuring customers never see unconfigured restaurants.

---

## Slide 4: Restaurant Partner Panel
### **Full Menu & Restaurant Management**
- **Profile Configuration:** Edit restaurant name, description, address, opening/closing hours, and precise map location.
- **Activation Guardrails:** A restaurant can only be toggled "Open" (`is_active = true`) if it has a valid map location and at least one available menu item.
- **Menu Management:** Add/edit dishes with categories and Supabase Storage image picker.

---

## Slide 5: Courier Panel & Real-Time Navigation
### **Live Delivery & Route Estimation**
- **GPS Integration:** Real-time tracking using `geolocator` with accuracy settings and permission handling.
- **Route Estimation (`RouteEstimate`):** Automatically calculates distance and estimated travel time from courier to restaurant and customer.
- **Interactive Map (`CourierMap`):** Custom pins for restaurant, customer, and live courier position with auto-recentering.

---

## Slide 6: Customer Experience & Checkout
### **Seamless Ordering & Live Tracking**
- **Persistent Cart:** `SharedPreferences` backed cart persistence that safely restores items across app restarts.
- **Mandatory Map Pinning:** Checkout requires customers to pin their exact delivery location on the map for the courier.
- **Real-Time Tracking:** Live status updates (`pending` → `accepted` → `preparing` → `ready_for_pickup` → `delivered`) with item breakdowns (`OrderLinesView`).

---

## Slide 7: Technical Highlights & Robustness
### **Advanced Engineering Patterns**
- **`liveQuery` Utility:** Combines Supabase Realtime streams with periodic polling (`Timer`) to guarantee UI updates even during network reconnections.
- **Row Level Security (RLS):** Strict PostgreSQL policies protecting all tables (`orders`, `order_items`, `restaurants`, `profiles`).
- **Unit & Widget Testing:** Comprehensive test suite (`flutter test`) verifying cart logic, persistence, models, and UI components with 100% passing rate.

---

## Slide 8: Conclusion & Deployment
### **Production-Ready & Cloud-Enabled**
- **CI/CD Pipeline:** GitHub Actions workflow (`ci.yml`) automating `flutter analyze` and `flutter test` on every push.
- **Cross-Platform:** Fully optimized for Android, iOS, and Web.
- **Future Ready:** Scalable architecture prepared for payment gateways (Click/Payme) and push notifications (FCM).
