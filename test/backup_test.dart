import 'package:flutter_test/flutter_test.dart';
import 'package:inventar_app/models/location.dart';
import 'package:inventar_app/models/product.dart';
import 'package:inventar_app/services/backup_service.dart';
import 'package:inventar_app/services/database_service.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Batch;

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Frische Datenbank für den Testlauf.
    await databaseFactory
        .deleteDatabase(join(await getDatabasesPath(), 'inventar.db'));
  });

  test('Export und Import stellen alle Daten wieder her', () async {
    final db = DatabaseService.instance;
    final backup = BackupService.instance;

    await db.insertLocation(
        const StorageLocation(name: 'Kühlschrank', color: 0xFF1E88E5));
    final locations = await db.getLocations();
    final locationId = locations.single.id;

    await db.saveProduct(Product(
      name: 'Milch',
      locationId: locationId,
      notes: 'Bio',
      batches: [
        Batch(quantity: 2, expiryDate: DateTime(2027, 3, 1)),
        const Batch(quantity: 1),
      ],
    ));

    final settings = <String, Object?>{
      'warnDays': 10,
      'reminderDays': 5,
      'reminderHour': 8,
      'reminderMinute': 30,
    };
    final export = await backup.buildExport(settings);

    // Daten verändern, dann Sicherung einspielen.
    await db.replaceAll(locations: const [], products: const []);
    expect(await db.getProducts(), isEmpty);

    final restoredSettings = await backup.restore(export);
    expect(restoredSettings?['warnDays'], 10);

    final restoredLocations = await db.getLocations();
    expect(restoredLocations.single.name, 'Kühlschrank');
    expect(restoredLocations.single.color, 0xFF1E88E5);

    final restoredProducts = await db.getProducts();
    final product = restoredProducts.single;
    expect(product.name, 'Milch');
    expect(product.notes, 'Bio');
    expect(product.locationId, restoredLocations.single.id);
    expect(product.totalQuantity, 3);
    expect(product.nextExpiry, DateTime(2027, 3, 1));
  });

  test('Import lehnt fremde Dateien ab', () async {
    expect(
      () => BackupService.instance.restore({'app': 'andere_app'}),
      throwsFormatException,
    );
  });
}
