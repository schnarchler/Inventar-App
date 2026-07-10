enum ExpiryStatus { expired, expiringSoon, ok, none }

/// Schwelle in Tagen, ab der ein Posten als „läuft bald ab“ (orange) gilt.
/// Wird beim App-Start und bei Änderungen aus den Einstellungen gesetzt.
int expiryWarnDays = 7;

/// Tage bis zum Ablauf; negativ = bereits abgelaufen, null = kein Datum.
int? daysUntil(DateTime? expiry) {
  if (expiry == null) return null;
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
  return expiryDay.difference(startOfToday).inDays;
}

ExpiryStatus statusFor(int? daysUntilExpiry) {
  final days = daysUntilExpiry;
  if (days == null) return ExpiryStatus.none;
  if (days < 0) return ExpiryStatus.expired;
  if (days <= expiryWarnDays) return ExpiryStatus.expiringSoon;
  return ExpiryStatus.ok;
}

/// Ein Bestand (Posten) eines Produkts: Menge mit eigenem Ablaufdatum.
class Batch {
  final int? id;
  final int? productId;
  final int quantity;
  final DateTime? expiryDate;

  const Batch({
    this.id,
    this.productId,
    required this.quantity,
    this.expiryDate,
  });

  int? get daysUntilExpiry => daysUntil(expiryDate);
  ExpiryStatus get status => statusFor(daysUntilExpiry);

  Map<String, Object?> toMap() => {
        'id': id,
        'productId': productId,
        'quantity': quantity,
        'expiryDate': expiryDate?.millisecondsSinceEpoch,
      };

  factory Batch.fromMap(Map<String, Object?> map) => Batch(
        id: map['id'] as int?,
        productId: map['productId'] as int?,
        quantity: map['quantity'] as int,
        expiryDate: map['expiryDate'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(map['expiryDate'] as int),
      );
}

class Product {
  final int? id;
  final String name;
  final int? locationId;
  final String? notes;
  final List<Batch> batches;

  const Product({
    this.id,
    required this.name,
    this.locationId,
    this.notes,
    this.batches = const [],
  });

  int get totalQuantity => batches.fold(0, (sum, b) => sum + b.quantity);

  /// Frühestes Ablaufdatum aller Bestände.
  DateTime? get nextExpiry {
    DateTime? earliest;
    for (final batch in batches) {
      final date = batch.expiryDate;
      if (date == null) continue;
      if (earliest == null || date.isBefore(earliest)) earliest = date;
    }
    return earliest;
  }

  int? get daysUntilExpiry => daysUntil(nextExpiry);
  ExpiryStatus get status => statusFor(daysUntilExpiry);

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'locationId': locationId,
        'notes': notes,
      };

  factory Product.fromMap(Map<String, Object?> map,
          {List<Batch> batches = const []}) =>
      Product(
        id: map['id'] as int?,
        name: map['name'] as String,
        locationId: map['locationId'] as int?,
        notes: map['notes'] as String?,
        batches: batches,
      );
}
