import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/inventory_provider.dart';
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

String expiryLabel(Product product) {
  final days = product.daysUntilExpiry;
  if (days == null) return 'Kein Ablaufdatum';
  final date = DateFormat('dd.MM.yyyy').format(product.expiryDate!);
  if (days < -1) return 'Abgelaufen seit ${-days} Tagen ($date)';
  if (days == -1) return 'Gestern abgelaufen ($date)';
  if (days == 0) return 'Läuft heute ab ($date)';
  if (days == 1) return 'Läuft morgen ab ($date)';
  return 'Läuft in $days Tagen ab ($date)';
}

class ProductTile extends StatelessWidget {
  final Product product;

  const ProductTile({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final location = provider.locationById(product.locationId);
    final color = statusColor(product.status, context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            '${product.quantity}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(product.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(expiryLabel(product), style: TextStyle(color: color)),
            if (location != null)
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 14),
                  const SizedBox(width: 2),
                  Text(location.name),
                ],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: 'Menge verringern',
              onPressed: product.quantity > 0
                  ? () => provider.changeQuantity(product, -1)
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Menge erhöhen',
              onPressed: () => provider.changeQuantity(product, 1),
            ),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductFormScreen(product: product),
          ),
        ),
      ),
    );
  }
}
