import 'package:flutter_test/flutter_test.dart';
import 'package:inventar_app/models/product.dart';

void main() {
  DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  group('Product.status', () {
    test('ohne Ablaufdatum → none', () {
      const product = Product(name: 'Salz', quantity: 1);
      expect(product.status, ExpiryStatus.none);
      expect(product.daysUntilExpiry, isNull);
    });

    test('gestern abgelaufen → expired', () {
      final product = Product(
        name: 'Milch',
        quantity: 1,
        expiryDate: today().subtract(const Duration(days: 1)),
      );
      expect(product.status, ExpiryStatus.expired);
      expect(product.daysUntilExpiry, -1);
    });

    test('läuft heute ab → expiringSoon', () {
      final product = Product(name: 'Joghurt', quantity: 2, expiryDate: today());
      expect(product.status, ExpiryStatus.expiringSoon);
      expect(product.daysUntilExpiry, 0);
    });

    test('läuft in 7 Tagen ab → expiringSoon', () {
      final product = Product(
        name: 'Käse',
        quantity: 1,
        expiryDate: today().add(const Duration(days: 7)),
      );
      expect(product.status, ExpiryStatus.expiringSoon);
    });

    test('läuft in 8 Tagen ab → ok', () {
      final product = Product(
        name: 'Nudeln',
        quantity: 3,
        expiryDate: today().add(const Duration(days: 8)),
      );
      expect(product.status, ExpiryStatus.ok);
      expect(product.daysUntilExpiry, 8);
    });
  });

  test('toMap/fromMap ist verlustfrei', () {
    final product = Product(
      id: 5,
      name: 'Reis',
      quantity: 2,
      locationId: 3,
      expiryDate: DateTime(2027, 1, 15),
      notes: 'Vorratsschrank oben',
    );
    final restored = Product.fromMap(product.toMap());
    expect(restored.id, product.id);
    expect(restored.name, product.name);
    expect(restored.quantity, product.quantity);
    expect(restored.locationId, product.locationId);
    expect(restored.expiryDate, product.expiryDate);
    expect(restored.notes, product.notes);
  });
}
