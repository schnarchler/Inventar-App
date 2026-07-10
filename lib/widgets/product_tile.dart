import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/location.dart';
import '../models/product.dart';
import '../screens/product_form_screen.dart';

Color statusColor(ExpiryStatus status, BuildContext context) {
  switch (status) {
    case ExpiryStatus.expired:
      return Colors.red.shade700;
    case ExpiryStatus.expiringSoon:
      return Colors.orange.shade800;
    case ExpiryStatus.ok:
      return Colors.green.shade700;
    case ExpiryStatus.none:
      return Theme.of(context).colorScheme.outline;
  }
}

String expiryLabel(DateTime? expiryDate) {
  final days = daysUntil(expiryDate);
  if (days == null) return 'Kein Ablaufdatum';
  final date = DateFormat('dd.MM.yyyy').format(expiryDate!);
  if (days < -1) return 'Abgelaufen seit ${-days} Tagen ($date)';
  if (days == -1) return 'Gestern abgelaufen ($date)';
  if (days == 0) return 'Läuft heute ab ($date)';
  if (days == 1) return 'Läuft morgen ab ($date)';
  return 'Läuft in $days Tagen ab ($date)';
}

/// Runde Mengen-Anzeige wie im Vorbild-Design.
class QuantityPill extends StatelessWidget {
  final int quantity;

  const QuantityPill({super.key, required this.quantity});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$quantity',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Kleiner farbiger Chip mit dem Namen des Ortes.
class LocationChip extends StatelessWidget {
  final StorageLocation location;

  const LocationChip({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    final color = location.color != null
        ? Color(location.color!)
        : Theme.of(context).colorScheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.place_outlined, size: 13, color: color),
          const SizedBox(width: 3),
          Text(
            location.name,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Produktzeile: Name, Ablauf-Info, Mengen-Badge. Tippen öffnet das Produkt.
class ProductRow extends StatelessWidget {
  final Product product;

  /// Wenn gesetzt, zeigt die Zeile diesen einzelnen Bestand (Übersicht);
  /// sonst Gesamtmenge und nächstes Ablaufdatum des Produkts.
  final Batch? batch;

  final StorageLocation? location;

  const ProductRow({super.key, required this.product, this.batch, this.location});

  @override
  Widget build(BuildContext context) {
    final expiry = batch?.expiryDate ?? product.nextExpiry;
    final status = batch?.status ?? product.status;
    final quantity = batch?.quantity ?? product.totalQuantity;
    final color = statusColor(status, context);
    final batchCount = product.batches.length;

    return ListTile(
      title: Text(product.name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (expiry != null)
            Text(expiryLabel(expiry),
                style: TextStyle(color: color, fontSize: 13)),
          if (batch == null && batchCount > 1)
            Text('$batchCount Posten mit eigenen Ablaufdaten',
                style: const TextStyle(fontSize: 12)),
          if (location != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: LocationChip(location: location!),
            ),
        ],
      ),
      trailing: QuantityPill(quantity: quantity),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductFormScreen(product: product),
        ),
      ),
    );
  }
}
