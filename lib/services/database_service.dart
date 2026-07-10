import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' hide Batch;

import '../models/location.dart';
import '../models/product.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'inventar.db');
    return openDatabase(
      path,
      version: 2,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE locations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            color INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            locationId INTEGER,
            notes TEXT,
            FOREIGN KEY (locationId) REFERENCES locations (id) ON DELETE SET NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE batches (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            productId INTEGER NOT NULL,
            quantity INTEGER NOT NULL DEFAULT 1,
            expiryDate INTEGER,
            FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // v1 → v2: Orte bekommen eine Farbe; Menge/Ablaufdatum wandern
          // vom Produkt in eine eigene Bestands-Tabelle (mehrere Posten
          // mit unterschiedlichen Ablaufdaten pro Produkt).
          await db.execute('ALTER TABLE locations ADD COLUMN color INTEGER');
          await db.execute('ALTER TABLE products RENAME TO products_old');
          await db.execute('''
            CREATE TABLE products (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              locationId INTEGER,
              notes TEXT,
              FOREIGN KEY (locationId) REFERENCES locations (id) ON DELETE SET NULL
            )
          ''');
          await db.execute('''
            INSERT INTO products (id, name, locationId, notes)
            SELECT id, name, locationId, notes FROM products_old
          ''');
          await db.execute('''
            CREATE TABLE batches (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              productId INTEGER NOT NULL,
              quantity INTEGER NOT NULL DEFAULT 1,
              expiryDate INTEGER,
              FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
            )
          ''');
          await db.execute('''
            INSERT INTO batches (productId, quantity, expiryDate)
            SELECT id, quantity, expiryDate FROM products_old
          ''');
          await db.execute('DROP TABLE products_old');
        }
      },
    );
  }

  // ---------- Produkte & Bestände ----------

  Future<List<Product>> getProducts() async {
    final db = await database;
    final productRows =
        await db.query('products', orderBy: 'name COLLATE NOCASE ASC');
    final batchRows = await db.query('batches',
        orderBy: 'expiryDate IS NULL, expiryDate ASC');

    final batchesByProduct = <int, List<Batch>>{};
    for (final row in batchRows) {
      final batch = Batch.fromMap(row);
      batchesByProduct.putIfAbsent(batch.productId!, () => []).add(batch);
    }
    return productRows
        .map((row) => Product.fromMap(row,
            batches: batchesByProduct[row['id'] as int] ?? const []))
        .toList();
  }

  Future<List<Batch>> getBatches(int productId) async {
    final db = await database;
    final rows = await db
        .query('batches', where: 'productId = ?', whereArgs: [productId]);
    return rows.map(Batch.fromMap).toList();
  }

  /// Legt ein Produkt an bzw. aktualisiert es und ersetzt seine Bestände.
  /// Gibt das gespeicherte Produkt mit den neuen Bestands-IDs zurück.
  Future<Product> saveProduct(Product product) async {
    final db = await database;
    late int productId;
    final savedBatches = <Batch>[];

    await db.transaction((txn) async {
      if (product.id == null) {
        productId = await txn.insert('products', product.toMap()..remove('id'));
      } else {
        productId = product.id!;
        await txn.update('products', product.toMap(),
            where: 'id = ?', whereArgs: [productId]);
        await txn.delete('batches',
            where: 'productId = ?', whereArgs: [productId]);
      }
      for (final batch in product.batches) {
        final map = batch.toMap()
          ..remove('id')
          ..['productId'] = productId;
        final batchId = await txn.insert('batches', map);
        savedBatches.add(Batch(
          id: batchId,
          productId: productId,
          quantity: batch.quantity,
          expiryDate: batch.expiryDate,
        ));
      }
    });

    return Product(
      id: productId,
      name: product.name,
      locationId: product.locationId,
      notes: product.notes,
      batches: savedBatches,
    );
  }

  Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  /// Ersetzt sämtliche Daten (für den Import einer Sicherung).
  Future<void> replaceAll({
    required List<StorageLocation> locations,
    required List<Product> products,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('batches');
      await txn.delete('products');
      await txn.delete('locations');
      for (final location in locations) {
        await txn.insert('locations', location.toMap());
      }
      for (final product in products) {
        await txn.insert('products', product.toMap());
        for (final batch in product.batches) {
          final map = batch.toMap()
            ..remove('id')
            ..['productId'] = product.id;
          await txn.insert('batches', map);
        }
      }
    });
  }

  // ---------- Orte ----------

  Future<List<StorageLocation>> getLocations() async {
    final db = await database;
    final rows =
        await db.query('locations', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(StorageLocation.fromMap).toList();
  }

  Future<void> insertLocation(StorageLocation location) async {
    final db = await database;
    await db.insert('locations', location.toMap()..remove('id'));
  }

  Future<void> updateLocation(StorageLocation location) async {
    final db = await database;
    await db.update('locations', location.toMap(),
        where: 'id = ?', whereArgs: [location.id]);
  }

  Future<void> deleteLocation(int id) async {
    final db = await database;
    await db.delete('locations', where: 'id = ?', whereArgs: [id]);
  }
}
