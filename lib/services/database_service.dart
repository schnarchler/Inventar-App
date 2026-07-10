import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE locations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            quantity INTEGER NOT NULL DEFAULT 1,
            locationId INTEGER,
            expiryDate INTEGER,
            notes TEXT,
            FOREIGN KEY (locationId) REFERENCES locations (id) ON DELETE SET NULL
          )
        ''');
      },
    );
  }

  // ---------- Produkte ----------

  Future<List<Product>> getProducts() async {
    final db = await database;
    final rows = await db.query('products', orderBy: 'expiryDate IS NULL, expiryDate ASC, name COLLATE NOCASE ASC');
    return rows.map(Product.fromMap).toList();
  }

  Future<Product> insertProduct(Product product) async {
    final db = await database;
    final id = await db.insert('products', product.toMap()..remove('id'));
    return product.copyWith(id: id);
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update('products', product.toMap(),
        where: 'id = ?', whereArgs: [product.id]);
  }

  Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Orte ----------

  Future<List<StorageLocation>> getLocations() async {
    final db = await database;
    final rows = await db.query('locations', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(StorageLocation.fromMap).toList();
  }

  Future<StorageLocation> insertLocation(StorageLocation location) async {
    final db = await database;
    final id = await db.insert('locations', location.toMap()..remove('id'));
    return location.copyWith(id: id);
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
