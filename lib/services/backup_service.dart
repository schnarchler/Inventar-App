import '../models/location.dart';
import '../models/product.dart';
import 'database_service.dart';

/// Erstellt und liest Sicherungen im JSON-Format (Fächer, Produkte,
/// Posten und Einstellungen). Ablaufdaten werden als ISO-Datum abgelegt,
/// damit die Datei auch von Hand lesbar bleibt.
class BackupService {
  static final BackupService instance = BackupService._();
  BackupService._();

  static const _appId = 'inventar_app';
  static const _format = 1;

  final _db = DatabaseService.instance;

  Future<Map<String, Object?>> buildExport(
      Map<String, Object?> settings) async {
    final locations = await _db.getLocations();
    final products = await _db.getProducts();
    return {
      'app': _appId,
      'format': _format,
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': settings,
      'locations': [
        for (final location in locations)
          {
            'id': location.id,
            'name': location.name,
            'color': location.color,
          },
      ],
      'products': [
        for (final product in products)
          {
            'id': product.id,
            'name': product.name,
            'locationId': product.locationId,
            'notes': product.notes,
            'batches': [
              for (final batch in product.batches)
                {
                  'quantity': batch.quantity,
                  'expiryDate': batch.expiryDate == null
                      ? null
                      : _dateToString(batch.expiryDate!),
                },
            ],
          },
      ],
    };
  }

  /// Ersetzt alle Daten durch den Inhalt der Sicherung und gibt die darin
  /// gespeicherten Einstellungen zurück (falls vorhanden).
  Future<Map<String, Object?>?> restore(Map<String, Object?> data) async {
    if (data['app'] != _appId || data['format'] is! int) {
      throw const FormatException('Keine gültige Inventar-Sicherung.');
    }
    if ((data['format'] as int) > _format) {
      throw const FormatException(
          'Die Sicherung stammt aus einer neueren App-Version.');
    }

    final locations = <StorageLocation>[
      for (final raw in (data['locations'] as List? ?? const []))
        StorageLocation(
          id: (raw as Map)['id'] as int?,
          name: raw['name'] as String,
          color: raw['color'] as int?,
        ),
    ];
    final products = <Product>[
      for (final raw in (data['products'] as List? ?? const []))
        Product(
          id: (raw as Map)['id'] as int?,
          name: raw['name'] as String,
          locationId: raw['locationId'] as int?,
          notes: raw['notes'] as String?,
          batches: [
            for (final b in (raw['batches'] as List? ?? const []))
              Batch(
                quantity: (b as Map)['quantity'] as int,
                expiryDate: b['expiryDate'] == null
                    ? null
                    : DateTime.parse(b['expiryDate'] as String),
              ),
          ],
        ),
    ];

    await _db.replaceAll(locations: locations, products: products);
    return data['settings'] as Map<String, Object?>?;
  }

  String _dateToString(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
