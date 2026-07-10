import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/inventory_provider.dart';
import '../widgets/product_tile.dart';

/// Übersicht: kleines Dashboard oben, darunter was abgelaufen ist
/// (ersetzen) und was als Nächstes abläuft — jeder Posten einzeln.
class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final entries = provider.expiryEntries;
    final expired =
        entries.where((e) => e.batch.status == ExpiryStatus.expired).toList();
    final soon = entries
        .where((e) => e.batch.status == ExpiryStatus.expiringSoon)
        .toList();
    final upcoming =
        entries.where((e) => e.batch.status == ExpiryStatus.ok).toList();

    if (provider.products.isEmpty) {
      return const Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Noch keine Produkte.\n'
                'Füge unter „Produkte“ etwas hinzu.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final totalPieces =
        provider.products.fold(0, (sum, p) => sum + p.totalQuantity);
    // Effektive Stückzahlen (nicht Anzahl betroffener Produkte):
    // 2 ablaufende Spritzen zählen als 2, auch wenn es 1 Produkt ist.
    final expiredPieces =
        expired.fold(0, (sum, e) => sum + e.batch.quantity);
    final soonPieces = soon.fold(0, (sum, e) => sum + e.batch.quantity);
    final expiredColor = statusColor(ExpiryStatus.expired, context);
    final soonColor = statusColor(ExpiryStatus.expiringSoon, context);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Abgelaufen',
                  value: expiredPieces,
                  icon: Icons.error_outline,
                  iconColor: expiredColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  label: 'Nächste $expiryWarnDays Tage',
                  value: soonPieces,
                  icon: Icons.warning_amber_outlined,
                  iconColor: soonColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  label: 'Bestand (Stück)',
                  value: totalPieces,
                  icon: Icons.inventory_2_outlined,
                  iconColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Für deine Produkte sind noch keine Ablaufdaten hinterlegt.',
              textAlign: TextAlign.center,
            ),
          ),
        if (expired.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.error_outline,
            color: expiredColor,
            title: 'Abgelaufen – ersetzen ($expiredPieces Stück)',
          ),
          ..._tiles(context, expired, provider),
        ],
        if (soon.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.warning_amber_outlined,
            color: soonColor,
            title: 'Läuft in den nächsten $expiryWarnDays Tagen ab '
                '($soonPieces Stück)',
          ),
          ..._tiles(context, soon, provider),
        ],
        if (upcoming.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.schedule_outlined,
            color: statusColor(ExpiryStatus.ok, context),
            title: 'Demnächst',
          ),
          ..._tiles(context, upcoming, provider),
        ],
      ],
    );
  }

  List<Widget> _tiles(BuildContext context, List<ExpiryEntry> entries,
          InventoryProvider provider) =>
      [
        for (final entry in entries)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: ProductRow(
              product: entry.product,
              batch: entry.batch,
              location: provider.locationById(entry.product.locationId),
            ),
          ),
      ];
}

/// Kennzahl-Kachel: Beschriftung + Icon oben, große Zahl darunter.
/// Die Statusfarbe sitzt nur am Icon; die Zahl bleibt in Textfarbe.
class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color iconColor;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
