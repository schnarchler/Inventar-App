import 'package:flutter_test/flutter_test.dart';
import 'package:inventar_app/models/product.dart';

void main() {
  DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  group('Batch.status', () {
    test('ohne Ablaufdatum → none', () {
      const batch = Batch(quantity: 1);
      expect(batch.status, ExpiryStatus.none);
      expect(batch.daysUntilExpiry, isNull);
    });

    test('gestern abgelaufen → expired', () {
      final batch = Batch(
        quantity: 1,
        expiryDate: today().subtract(const Duration(days: 1)),
      );
      expect(batch.status, ExpiryStatus.expired);
      expect(batch.daysUntilExpiry, -1);
    });

    test('läuft heute ab → expiringSoon', () {
      final batch = Batch(quantity: 2, expiryDate: today());
      expect(batch.status, ExpiryStatus.expiringSoon);
      expect(batch.daysUntilExpiry, 0);
    });

    test('läuft in 7 Tagen ab → expiringSoon', () {
      final batch = Batch(
        quantity: 1,
        expiryDate: today().add(const Duration(days: 7)),
      );
      expect(batch.status, ExpiryStatus.expiringSoon);
    });

    test('läuft in 8 Tagen ab → ok', () {
      final batch = Batch(
        quantity: 3,
        expiryDate: today().add(const Duration(days: 8)),
      );
      expect(batch.status, ExpiryStatus.ok);
      expect(batch.daysUntilExpiry, 8);
    });
  });

  group('Product mit mehreren Posten', () {
    test('Gesamtmenge ist Summe der Posten', () {
      final product = Product(
        name: 'Milch',
        batches: [
          Batch(quantity: 2, expiryDate: today().add(const Duration(days: 30))),
          Batch(quantity: 1, expiryDate: today().add(const Duration(days: 3))),
          const Batch(quantity: 4),
        ],
      );
      expect(product.totalQuantity, 7);
    });

    test('nextExpiry ist das früheste Datum', () {
      final soon = today().add(const Duration(days: 3));
      final product = Product(
        name: 'Milch',
        batches: [
          Batch(quantity: 2, expiryDate: today().add(const Duration(days: 30))),
          Batch(quantity: 1, expiryDate: soon),
          const Batch(quantity: 4),
        ],
      );
      expect(product.nextExpiry, soon);
      expect(product.status, ExpiryStatus.expiringSoon);
    });

    test('ohne Posten: Menge 0, kein Status', () {
      const product = Product(name: 'Salz');
      expect(product.totalQuantity, 0);
      expect(product.nextExpiry, isNull);
      expect(product.status, ExpiryStatus.none);
    });
  });

  test('Batch toMap/fromMap ist verlustfrei', () {
    final batch = Batch(
      id: 7,
      productId: 5,
      quantity: 2,
      expiryDate: DateTime(2027, 1, 15),
    );
    final restored = Batch.fromMap(batch.toMap());
    expect(restored.id, batch.id);
    expect(restored.productId, batch.productId);
    expect(restored.quantity, batch.quantity);
    expect(restored.expiryDate, batch.expiryDate);
  });
}
