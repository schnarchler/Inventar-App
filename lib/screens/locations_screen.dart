import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/location.dart';
import '../providers/inventory_provider.dart';

class LocationsScreen extends StatelessWidget {
  const LocationsScreen({super.key});

  Future<String?> _promptForName(BuildContext context,
      {String? initial}) async {
    final controller = TextEditingController(text: initial ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(initial == null ? 'Neuer Ort' : 'Ort umbenennen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Name (z. B. Kühlschrank, Keller)',
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    controller.dispose();
    return (name == null || name.isEmpty) ? null : name;
  }

  Future<void> _addLocation(BuildContext context) async {
    final provider = context.read<InventoryProvider>();
    final name = await _promptForName(context);
    if (name != null) await provider.addLocation(name);
  }

  Future<void> _deleteLocation(
      BuildContext context, StorageLocation location) async {
    final provider = context.read<InventoryProvider>();
    final productCount =
        provider.products.where((p) => p.locationId == location.id).length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ort löschen?'),
        content: Text(
          productCount == 0
              ? '„${location.name}“ wird entfernt.'
              : '„${location.name}“ wird entfernt. $productCount Produkt(e) '
                  'behalten dann keinen Ort mehr.',
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

    return Scaffold(
      body: locations.isEmpty
          ? const Center(
              child: Text(
                'Noch keine Orte.\nTippe auf +, um z. B. „Kühlschrank“ anzulegen.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final location = locations[index];
                final count = provider.products
                    .where((p) => p.locationId == location.id)
                    .length;
                return ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(location.name),
                  subtitle: Text('$count Produkt(e)'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Umbenennen',
                        onPressed: () async {
                          final name = await _promptForName(context,
                              initial: location.name);
                          if (name != null && context.mounted) {
                            await context
                                .read<InventoryProvider>()
                                .renameLocation(location, name);
                          }
                        },
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
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addLocation',
        onPressed: () => _addLocation(context),
        tooltip: 'Ort hinzufügen',
        child: const Icon(Icons.add),
      ),
    );
  }
}
