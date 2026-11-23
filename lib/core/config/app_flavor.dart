import '../../features/auth/data/user_profile.dart';

/// OsonGo bitta kod bazasidan uchta alohida ilova sifatida yig'iladi.
/// Qaysi ilova ishlayotgani ilova ishga tushganda bir marta belgilanadi.
enum AppFlavor {
  /// Mijozlar uchun: katalog, savat, buyurtma. Ro'yxatdan o'tish shu yerda.
  customer,

  /// Restoran egalari va kuryerlar uchun. Hisobni admin beradi.
  partner,

  /// Administrator uchun: xodim qo'shish va chiqarish.
  admin;

  static AppFlavor current = AppFlavor.customer;

  /// Ilovaning to'liq nomi (MaterialApp sarlavhasi).
  String get appTitle => switch (this) {
    AppFlavor.customer => 'OsonGo — tez yetkazib berish',
    AppFlavor.partner => 'OsonGo Hamkor',
    AppFlavor.admin => 'OsonGo Admin',
  };

  /// Splash va kirish sahifasidagi qisqa yozuv.
  String get badge => switch (this) {
    AppFlavor.customer => 'OSONGO DELIVERY',
    AppFlavor.partner => 'OSONGO HAMKOR',
    AppFlavor.admin => 'OSONGO ADMIN',
  };

  String get loginSubtitle => switch (this) {
    AppFlavor.customer => 'Hisobingizga kiring',
    AppFlavor.partner => 'Restoran yoki kuryer hisobingiz bilan kiring',
    AppFlavor.admin => 'Administrator hisobi bilan kiring',
  };

  /// Faqat mijoz ilovasida o'zi ro'yxatdan o'tish mumkin.
  bool get allowsRegistration => this == AppFlavor.customer;

  /// Faqat mijoz ilovasida kirmasdan katalogni ko'rish mumkin.
  bool get allowsGuest => this == AppFlavor.customer;

  /// Faqat mijoz ilovasida birinchi ochilganda tanishtiruv ko'rsatiladi.
  bool get showsOnboarding => this == AppFlavor.customer;

  /// Bu ilova shu foydalanuvchi uchunmi?
  bool accepts(UserProfile p) => switch (this) {
    AppFlavor.customer => p.role == UserRole.customer,
    AppFlavor.partner =>
      p.role == UserRole.restaurant ||
          p.role == UserRole.courier ||
          p.ownsRestaurant,
    AppFlavor.admin => p.role == UserRole.admin,
  };

  /// Noto'g'ri ilovaga kirgan foydalanuvchiga qaysi ilovadan foydalanishni
  /// aytadigan matn.
  String wrongAppMessage(UserRole role) => switch (role) {
    UserRole.admin => 'Bu hisob administratorniki. "OsonGo Admin" '
        'ilovasidan foydalaning.',
    UserRole.restaurant ||
    UserRole.courier => 'Bu hisob xodimniki (${role.label}). "OsonGo Hamkor" '
        'ilovasidan foydalaning.',
    UserRole.customer => 'Bu ilova xodimlar uchun. Buyurtma berish uchun '
        '"OsonGo" ilovasidan foydalaning.',
  };
}
