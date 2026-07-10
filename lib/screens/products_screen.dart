import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/location.dart';
import '../models/product.dart';
import '../providers/inventory_provider.dart';
import '../widgets/product_tile.dart';

/// Produkte gruppiert nach Orten als farbige, aufklappbare Karten.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _query = '';

  /// IDs der aufgeklappten Orte (null = Gruppe „Ohne Ort“);
  /// standardmäßig ist alles zugeklappt.
  final Set<int?> _expanded = {};

  bool get _searching => _query.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();

    List<Product> productsFor(int? locationId) => provider.products
        .where((p) =>
            p.locationId == locationId &&
            p.name.toLowerCase().contains(_query.toLowerCase().trim()))
        .toList();

    final groups = <(StorageLocation?, List<Product>)>[
      for (final location in provider.locations)
        (location, productsFor(location.id)),
      (null, productsFor(null)),
    ]..removeWhere((g) => g.$2.isEmpty && (_searching || g.$1 == null));

    final allGroupKeys = groups.map((g) => g.$1?.id).toSet();
    final allExpanded =
        allGroupKeys.isNotEmpty && allGroupKeys.every(_expanded.contains);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SearchBar(
            hintText: 'Produkt suchen …',
            leading: const Icon(Icons.search),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: groups.isEmpty
                ? null
                : () => setState(() {
                      if (allExpanded) {
                        _expanded.clear();
                      } else {
                        _expanded.addAll(allGroupKeys);
                      }
                    }),
            icon: Icon(allExpanded ? Icons.unfold_less : Icons.unfold_more,
                size: 18),
            label: Text(allExpanded ? 'Alle zuklappen' : 'Alle aufklappen'),
          ),
        ),
        Expanded(
          child: groups.isEmpty
              ? Center(
                  child: Text(
                    _searching
                        ? 'Keine Treffer für „${_query.trim()}“.'
                        : 'Noch keine Produkte.\nTippe auf +, um eines anzulegen.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                  children: [
                    for (final (location, products) in groups)
                      _LocationSection(
                        location: location,
                        products: products,
                        // Bei aktiver Suche immer aufgeklappt anzeigen.
                        expanded: _searching ||
                            _expanded.contains(location?.id),
                        onToggle: () => setState(() {
                          _expanded.contains(location?.id)
                              ? _expanded.remove(location?.id)
                              : _expanded.add(location?.id);
                        }),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _LocationSection extends StatelessWidget {
  final StorageLocation? location;
  final List<Product> products;
  final bool expanded;
  final VoidCallback onToggle;

  const _LocationSection({
    required this.location,
    required this.products,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = locationDisplayColor(location, context);
    final totalQuantity =
        products.fold(0, (sum, p) => sum + p.totalQuantity);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.4),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Container(
              color: color.withValues(alpha: 0.08),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    location == null
                        ? Icons.help_outline
                        : Icons.place_outlined,
                    size: 18,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location?.name ?? 'Ohne Fach',
                      style: TextStyle(
                        color: location?.color != null
                            ? color
                            : scheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!expanded && products.isNotEmpty) ...[
                    QuantityPill(quantity: totalQuantity),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    expanded ? Icons.expand_less : Icons.chevron_right,
                    color: color,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            products.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('Keine Produkte in diesem Fach.'),
                  )
                : Column(
                    children: [
                      for (final (index, product) in products.indexed) ...[
                        if (index > 0) const Divider(height: 1, indent: 16),
                        ProductRow(product: product),
                      ],
                    ],
                  ),
        ],
      ),
    );
  }
}
