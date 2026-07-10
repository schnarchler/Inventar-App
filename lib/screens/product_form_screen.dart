import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/inventory_provider.dart';
import '../widgets/product_tile.dart';

class ProductFormScreen extends StatefulWidget {
  /// null = neues Produkt anlegen, sonst bearbeiten.
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

/// Bearbeitbarer Posten: Menge mit eigenem Ablaufdatum.
class _BatchEdit {
  int quantity;
  DateTime? expiryDate;

  _BatchEdit({this.quantity = 1, this.expiryDate});
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  int? _locationId;
  late final List<_BatchEdit> _batches;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _notesController = TextEditingController(text: product?.notes ?? '');
    _locationId = product?.locationId;
    _batches = product == null || product.batches.isEmpty
        ? [_BatchEdit()]
        : [
            for (final batch in product.batches)
              _BatchEdit(quantity: batch.quantity, expiryDate: batch.expiryDate),
          ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate(_BatchEdit batch) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: batch.expiryDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 30),
      helpText: 'Ablaufdatum wählen',
    );
    if (picked != null) setState(() => batch.expiryDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<InventoryProvider>();
    final navigator = Navigator.of(context);

    final notes = _notesController.text.trim();
    final product = Product(
      id: widget.product?.id,
      name: _nameController.text.trim(),
      locationId: _locationId,
      notes: notes.isEmpty ? null : notes,
      batches: [
        for (final batch in _batches)
          Batch(quantity: batch.quantity, expiryDate: batch.expiryDate),
      ],
    );

    await provider.saveProduct(product);
    navigator.pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Produkt löschen?'),
        content: Text('„${widget.product!.name}“ wird dauerhaft entfernt.'),
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
    if (confirmed != true || !mounted) return;
    final provider = context.read<InventoryProvider>();
    final navigator = Navigator.of(context);
    await provider.deleteProduct(widget.product!);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final locations = context.watch<InventoryProvider>().locations;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Produkt bearbeiten' : 'Neues Produkt'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Löschen',
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Bitte einen Namen eingeben'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              initialValue: _locationId,
              decoration: const InputDecoration(
                labelText: 'Fach',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Kein Fach'),
                ),
                ...locations.map(
                  (l) => DropdownMenuItem<int?>(
                    value: l.id,
                    // Fach-Name in der zugeteilten Farbe anzeigen.
                    child: Text(
                      l.name,
                      style: TextStyle(
                        color: locationDisplayColor(l, context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _locationId = value),
            ),
            const SizedBox(height: 20),
            Text(
              'Menge & Ablaufdaten',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Mehrere Posten möglich, z. B. 2 Stück bis März und 1 Stück bis Juli.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            for (final (index, batch) in _batches.indexed)
              _BatchRow(
                key: ObjectKey(batch),
                batch: batch,
                canDelete: _batches.length > 1,
                onChanged: () => setState(() {}),
                onPickDate: () => _pickExpiryDate(batch),
                onDelete: () => setState(() => _batches.removeAt(index)),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _batches.add(_BatchEdit())),
                icon: const Icon(Icons.add),
                label: const Text('Posten hinzufügen'),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notizen',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Speichern'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchRow extends StatelessWidget {
  final _BatchEdit batch;
  final bool canDelete;
  final VoidCallback onChanged;
  final VoidCallback onPickDate;
  final VoidCallback onDelete;

  const _BatchRow({
    super.key,
    required this.batch,
    required this.canDelete,
    required this.onChanged,
    required this.onPickDate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            tooltip: 'Menge verringern',
            onPressed: batch.quantity > 1
                ? () {
                    batch.quantity--;
                    onChanged();
                  }
                : null,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '${batch.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Menge erhöhen',
            onPressed: () {
              batch.quantity++;
              onChanged();
            },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextButton.icon(
              onPressed: onPickDate,
              icon: const Icon(Icons.event_outlined, size: 18),
              label: Text(
                batch.expiryDate == null
                    ? 'Kein Datum'
                    : DateFormat('dd.MM.yyyy').format(batch.expiryDate!),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (batch.expiryDate != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              tooltip: 'Datum entfernen',
              onPressed: () {
                batch.expiryDate = null;
                onChanged();
              },
            ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: 'Posten entfernen',
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
