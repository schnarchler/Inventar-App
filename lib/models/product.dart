enum ExpiryStatus { expired, expiringSoon, ok, none }

class Product {
  final int? id;
  final String name;
  final int quantity;
  final int? locationId;
  final DateTime? expiryDate;
  final String? notes;

  const Product({
    this.id,
    required this.name,
    required this.quantity,
    this.locationId,
    this.expiryDate,
    this.notes,
  });

  Product copyWith({
    int? id,
    String? name,
    int? quantity,
    int? Function()? locationId,
    DateTime? Function()? expiryDate,
    String? Function()? notes,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        locationId: locationId != null ? locationId() : this.locationId,
        expiryDate: expiryDate != null ? expiryDate() : this.expiryDate,
        notes: notes != null ? notes() : this.notes,
      );

  /// Tage bis zum Ablauf; negativ = bereits abgelaufen, null = kein Datum.
  int? get daysUntilExpiry {
    final expiry = expiryDate;
    if (expiry == null) return null;
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
    return expiryDay.difference(startOfToday).inDays;
  }

  ExpiryStatus get status {
    final days = daysUntilExpiry;
    if (days == null) return ExpiryStatus.none;
    if (days < 0) return ExpiryStatus.expired;
    if (days <= 7) return ExpiryStatus.expiringSoon;
    return ExpiryStatus.ok;
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'locationId': locationId,
        'expiryDate': expiryDate?.millisecondsSinceEpoch,
        'notes': notes,
      };

  factory Product.fromMap(Map<String, Object?> map) => Product(
        id: map['id'] as int?,
        name: map['name'] as String,
        quantity: map['quantity'] as int,
        locationId: map['locationId'] as int?,
        expiryDate: map['expiryDate'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(map['expiryDate'] as int),
        notes: map['notes'] as String?,
      );
}
