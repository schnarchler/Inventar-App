import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/inventory_provider.dart';
import '../widgets/product_tile.dart';

/// Übersicht: was ist abgelaufen (ersetzen) und was läuft als Nächstes ab.
class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final expired = provider.expiredProducts;
    final soon = provider.expiringSoonProducts;
    final upcoming = provider.expiringProducts
        .where((p) => p.status == ExpiryStatus.ok)
        .toList();

    if (expired.isEmpty && soon.isEmpty && upcoming.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Noch keine Produkte mit Ablaufdatum.\n'
                'Füge unter „Produkte“ etwas hinzu.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (expired.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.error_outline,
            color: Colors.red.shade700,
            title: 'Abgelaufen – ersetzen (${expired.length})',
          ),
          ...expired.map((p) => ProductTile(product: p)),
        ],
        if (soon.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.warning_amber_outlined,
            color: Colors.orange.shade800,
            title: 'Läuft in den nächsten 7 Tagen ab (${soon.length})',
          ),
          ...soon.map((p) => ProductTile(product: p)),
        ],
        if (upcoming.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.schedule_outlined,
            color: Colors.green.shade700,
            title: 'Demnächst',
          ),
          ...upcoming.map((p) => ProductTile(product: p)),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.color,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
