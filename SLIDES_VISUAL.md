# FoodGo Delivery Platform — Visual Presentation & Architecture Diagrams

> 💡 *Ushbu hujjat taqdimot va slaydlar uchun vizual sxemalar (Mermaid Diagrams) va arxitektura oqimlarini o'z ichiga oladi.*

---

## 1. 🌐 Tizim Arxitekturasi va Rollar Oqimi (System Architecture)

```mermaid
graph TD
    A[Admin] -->|Xodim qo'shish / O'chirish| B(Supabase Edge Functions)
    C[Restoran Hamkori] -->|Menyu & Profil boshqaruvi| D[(Supabase Database)]
    E[Kuryer] -->|Buyurtma olish & GPS Tracking| D
    F[Mijoz] -->|Savat, Buyurtma berish & Live Track| D
    B --> D
    D -->|Realtime + liveQuery| C
    D -->|Realtime + liveQuery| E
    D -->|Realtime + watchStatus| F
```

---

## 2. 🍔 Buyurtma Hayot Tsikli (Order Lifecycle Workflow)

```mermaid
stateDiagram-v2
    [*] --> pending: Mijoz buyurtma berdi
    pending --> accepted: Restoran tasdiqladi
    pending --> rejected: Restoran rad etdi
    accepted --> preparing: Tayyorlash boshlandi
    preparing --> ready_for_pickup: Tayyor (Kuryer kutilmoqda)
    ready_for_pickup --> courier_assigned: Kuryer qabul qildi
    courier_assigned --> picked_up: Kuryer olib ketdi
    picked_up --> on_the_way: Yo'lda
    on_the_way --> delivered: Yetkazib berildi
    delivered --> [*]
```

---

## 3. 👥 Foydalanuvchi Rollari va Huquqlar Matrikasi

| Rol (Role) | Asosiy Vazifasi | Ruxsat etilgan Sahifalar |
| :--- | :--- | :--- |
| **👑 Admin** | Restoran va kuryer xodimlarini boshqarish | `/admin` (Admin Panel) |
| **🍔 Restoran** | Menyu, taomlar, narx va ish vaqtini boshqarish | `/restaurant` (Restoran Paneli) |
| **🚴 Kuryer** | GPS orqali yaqin atrofdagi buyurtmalarni olish va yetkazish | `/courier` (Kuryer Paneli) |
| **👤 Mijoz** | Restoranlardan taom tanlash, savat va buyurtma berish | `/customer/home` (Mijoz Ilovasi) |

---

## 4. ⚡ Real-Time Ma'lumot Oqimi (`liveQuery` & Polling)

```mermaid
sequenceDiagram
    participant App as Flutter App
    participant RQ as liveQuery Utility
    participant SB as Supabase Realtime / DB
    
    App->>RQ: Stream tinglashni boshlaydi
    RQ->>SB: Ilk ma'lumotni yuklash (fetch)
    SB-->>RQ: Ma'lumotlar ro'yxati
    RQ-->>App: UI yangilanadi (Data)
    
    Note over SB,RQ: Ma'lumot o'zgarganda (INSERT/UPDATE/DELETE)
    SB-->>RQ: Realtime webhook signali
    RQ->>SB: Ma'lumotni qayta yuklash (load)
    SB-->>RQ: Yangi ma'lumotlar
    RQ-->>App: UI avtomatik yangilanadi
```

---

## 5. 📱 Ilova Ekranlari Tuzilishi (Screen Hierarchy)

```mermaid
graph LR
    Auth[Auth / Login] -->|RoleGate| Admin[Admin Panel]
    Auth -->|RoleGate| Rest[Restoran Paneli]
    Auth -->|RoleGate| Courier[Kuryer Paneli]
    Auth -->|RoleGate| Customer[Mijoz Shell & Home]
    Customer --> Cart[Savat & Checkout]
    Customer --> Orders[Buyurtmalar & Live Tracking]
```
