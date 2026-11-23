import 'package:flutter_test/flutter_test.dart';
import 'package:osongo/core/config/app_flavor.dart';
import 'package:osongo/features/auth/data/user_profile.dart';

UserProfile p(UserRole r, {bool owns = false}) =>
    UserProfile(id: 'x', role: r, ownsRestaurant: owns);

void main() {
  test('mijoz ilovasi faqat mijozni qabul qiladi', () {
    expect(AppFlavor.customer.accepts(p(UserRole.customer)), isTrue);
    expect(AppFlavor.customer.accepts(p(UserRole.courier)), isFalse);
    expect(AppFlavor.customer.accepts(p(UserRole.admin)), isFalse);
  });

  test('hamkor ilovasi restoran va kuryerni qabul qiladi', () {
    expect(AppFlavor.partner.accepts(p(UserRole.courier)), isTrue);
    expect(AppFlavor.partner.accepts(p(UserRole.restaurant)), isTrue);
    expect(AppFlavor.partner.accepts(p(UserRole.customer)), isFalse);
    expect(AppFlavor.partner.accepts(p(UserRole.admin)), isFalse);
  });

  test('admin ilovasi faqat adminni qabul qiladi', () {
    expect(AppFlavor.admin.accepts(p(UserRole.admin)), isTrue);
    expect(AppFlavor.admin.accepts(p(UserRole.customer)), isFalse);
  });
}
