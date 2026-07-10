import 'package:flutter/foundation.dart';

import '../models/location.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

/// Ein Eintrag für die Übersicht: ein Bestand (Posten) samt Produkt.
typedef ExpiryEntry = ({Product product, Batch batch});

class InventoryProvider extends ChangeNotifier {
  final _db = DatabaseService.instance;
  final _notifications = NotificationService.instance;

  List<Product> _products = [];
  List<StorageLocation> _locations = [];
  bool _loaded = false;

  List<Product> get products => _products;
  List<StorageLocation> get locations => _locations;
  bool get loaded => _loaded;

  /// Alle Bestände mit Ablaufdatum, sortiert nach Datum (nächstes zuerst).
  List<ExpiryEntry> get expiryEntries {
    final entries = <ExpiryEntry>[
      for (final product in _products)
        for (final batch in product.batches)
          if (batch.expiryDate != null) (product: product, batch: batch),
    ];
    entries.sort((a, b) => a.batch.expiryDate!.compareTo(b.batch.expiryDate!));
    return entries;
  }

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

  Future<void> saveProduct(Product product) async {
    if (product.id != null) {
      final oldBatches = await _db.getBatches(product.id!);
      await _notifications
          .cancelForBatches(oldBatches.map((b) => b.id!).toList());
    }
    final saved = await _db.saveProduct(product);
    await _notifications.scheduleForProduct(saved);
    await load();
  }

  Future<void> deleteProduct(Product product) async {
    if (product.id != null) {
      final batches = await _db.getBatches(product.id!);
      await _notifications.cancelForBatches(batches.map((b) => b.id!).toList());
      await _db.deleteProduct(product.id!);
    }
    await load();
  }

  /// Plant alle Erinnerungen neu, z. B. nach geänderten Einstellungen.
  Future<void> rescheduleAllNotifications() async {
    await _notifications.cancelAll();
    for (final product in _products) {
      await _notifications.scheduleForProduct(product);
    }
    // Status-Gruppierung (orange-Schwelle) neu berechnen lassen.
    notifyListeners();
  }

  // ---------- Orte ----------

  Future<void> addLocation(String name, int? color) async {
    await _db.insertLocation(StorageLocation(name: name, color: color));
    await load();
  }

  Future<void> updateLocation(StorageLocation location) async {
    await _db.updateLocation(location);
    await load();
  }

  Future<void> deleteLocation(StorageLocation location) async {
    if (location.id != null) {
      await _db.deleteLocation(location.id!);
    }
    await load();
  }
}
