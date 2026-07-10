import 'package:flutter/foundation.dart';

import '../models/location.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class InventoryProvider extends ChangeNotifier {
  final _db = DatabaseService.instance;
  final _notifications = NotificationService.instance;

  List<Product> _products = [];
  List<StorageLocation> _locations = [];
  bool _loaded = false;

  List<Product> get products => _products;
  List<StorageLocation> get locations => _locations;
  bool get loaded => _loaded;

  /// Produkte mit Ablaufdatum, sortiert nach Datum (nächstes zuerst).
  List<Product> get expiringProducts =>
      _products.where((p) => p.expiryDate != null).toList()
        ..sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));

  List<Product> get expiredProducts =>
      expiringProducts.where((p) => p.status == ExpiryStatus.expired).toList();

  List<Product> get expiringSoonProducts => expiringProducts
      .where((p) => p.status == ExpiryStatus.expiringSoon)
      .toList();

  Future<void> load() async {
    _products = await _db.getProducts();
    _locations = await _db.getLocations();
    _loaded = true;
    notifyListeners();
  }

  StorageLocation? locationById(int? id) {
    if (id == null) return null;
    for (final location in _locations) {
      if (location.id == id) return location;
    }
    return null;
  }

  // ---------- Produkte ----------

  Future<void> addProduct(Product product) async {
    final saved = await _db.insertProduct(product);
    await _notifications.scheduleForProduct(saved);
    await load();
  }

  Future<void> updateProduct(Product product) async {
    await _db.updateProduct(product);
    await _notifications.scheduleForProduct(product);
    await load();
  }

  Future<void> deleteProduct(Product product) async {
    if (product.id != null) {
      await _db.deleteProduct(product.id!);
      await _notifications.cancelForProduct(product.id!);
    }
    await load();
  }

  Future<void> changeQuantity(Product product, int delta) async {
    final newQuantity = (product.quantity + delta).clamp(0, 999999);
    await _db.updateProduct(product.copyWith(quantity: newQuantity));
    await load();
  }

  // ---------- Orte ----------

  Future<void> addLocation(String name) async {
    await _db.insertLocation(StorageLocation(name: name));
    await load();
  }

  Future<void> renameLocation(StorageLocation location, String name) async {
    await _db.updateLocation(location.copyWith(name: name));
    await load();
  }

  Future<void> deleteLocation(StorageLocation location) async {
    if (location.id != null) {
      await _db.deleteLocation(location.id!);
    }
    await load();
  }
}
