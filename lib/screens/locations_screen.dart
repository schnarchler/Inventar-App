import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/location.dart';
import '../providers/inventory_provider.dart';
import '../widgets/product_tile.dart';

/// Farbpalette für Fächer (ARGB-Werte).
const locationColorPalette = <int>[
  0xFFE53935, // Rot
  0xFFD81B60, // Pink
  0xFF8E24AA, // Lila
  0xFF5E35B1, // Dunkellila
  0xFF3949AB, // Indigo
  0xFF1E88E5, // Blau
  0xFF00ACC1, // Cyan
  0xFF00897B, // Petrol
  0xFF43A047, // Grün
  0xFF7CB342, // Hellgrün
  0xFFFB8C00, // Orange
  0xFF6D4C41, // Braun
];

/// Öffnet den Dialog zum Anlegen oder Bearbeiten eines Fachs.
Future<void> showLocationEditor(BuildContext context,
    {StorageLocation? existing}) async {
  final provider = context.read<InventoryProvider>();
  final result = await showDialog<({String name, int? color})>(
    context: context,
    builder: (_) => _LocationEditorDialog(existing: existing),
  );
  if (result == null) return;

  if (existing == null) {
    await provider.addLocation(result.name, result.color);
  } else {
    await provider.updateLocation(StorageLocation(
      id: existing.id,
      name: result.name,
      color: result.color,
    ));
  }
}

class _LocationEditorDialog extends StatefulWidget {
  final StorageLocation? existing;

  const _LocationEditorDialog({this.existing});

  @override
  State<_LocationEditorDialog> createState() => _LocationEditorDialogState();
}

class _LocationEditorDialogState extends State<_LocationEditorDialog> {
  late final TextEditingController _nameController;
  int? _color;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existing?.name ?? '');
    _color = widget.existing?.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop((name: name, color: _color));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Scrollbar, damit bei geöffneter Tastatur nichts überläuft.
      scrollable: true,
      title: Text(
          widget.existing == null ? 'Neues Fach' : 'Fach bearbeiten'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Name (z. B. Kühlschrank, Keller)',
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          const Text('Farbe', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ColorDot(
                color: null,
                selected: _color == null,
                onTap: () => setState(() => _color = null),
              ),
              for (final value in locationColorPalette)
                _ColorDot(
                  color: Color(value),
                  selected: _color == value,
                  onTap: () => setState(() => _color = value),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  /// null = „keine Farbe“.
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color ?? Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? scheme.onSurface : scheme.outlineVariant,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: color == null
            ? Icon(Icons.block, size: 18, color: scheme.outline)
            : selected
                ? const Icon(Icons.check, size: 20, color: Colors.white)
                : null,
      ),
    );
  }
}

class LocationsScreen extends StatelessWidget {
  const LocationsScreen({super.key});

  Future<void> _deleteLocation(
      BuildContext context, StorageLocation location) async {
    final provider = context.read<InventoryProvider>();
    final productCount =
        provider.products.where((p) => p.locationId == location.id).length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fach löschen?'),
        content: Text(
          productCount == 0
              ? '„${location.name}“ wird entfernt.'
              : '„${location.name}“ wird entfernt. $productCount Produkt(e) '
                  'behalten dann kein Fach mehr.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true) await provider.deleteLocation(location);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final locations = provider.locations;

    if (locations.isEmpty) {
      return const Center(
        child: Text(
          'Noch keine Fächer.\nTippe auf +, um z. B. „Kühlschrank“ anzulegen.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: locations.length,
      itemBuilder: (context, index) {
        final location = locations[index];
        final color = locationDisplayColor(location, context);
        final count = provider.products
            .where((p) => p.locationId == location.id)
            .length;
        return ListTile(
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: color,
            child: const Icon(Icons.place_outlined,
                size: 16, color: Colors.white),
          ),
          title: Text(location.name),
          subtitle: Text('$count Produkt(e)'),
          onTap: () => showLocationEditor(context, existing: location),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Bearbeiten',
                onPressed: () =>
                    showLocationEditor(context, existing: location),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Löschen',
                onPressed: () => _deleteLocation(context, location),
              ),
            ],
          ),
        );
      },
    );
  }
}
