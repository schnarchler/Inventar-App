import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/inventory_provider.dart';

class ProductFormScreen extends StatefulWidget {
  /// null = neues Produkt anlegen, sonst bearbeiten.
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  late int _quantity;
  int? _locationId;
  DateTime? _expiryDate;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _notesController = TextEditingController(text: product?.notes ?? '');
    _quantity = product?.quantity ?? 1;
    _locationId = product?.locationId;
    _expiryDate = product?.expiryDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 30),
      helpText: 'Ablaufdatum wählen',
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<InventoryProvider>();
    final navigator = Navigator.of(context);

    final notes = _notesController.text.trim();
    final product = Product(
      id: widget.product?.id,
      name: _nameController.text.trim(),
      quantity: _quantity,
      locationId: _locationId,
      expiryDate: _expiryDate,
      notes: notes.isEmpty ? null : notes,
    );

    if (_isEditing) {
      await provider.updateProduct(product);
    } else {
      await provider.addProduct(product);
    }
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
            Row(
              children: [
                const Text('Menge:', style: TextStyle(fontSize: 16)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _quantity > 0
                      ? () => setState(() => _quantity--)
                      : null,
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '$_quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _quantity++),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              initialValue: _locationId,
              decoration: const InputDecoration(
                labelText: 'Ort',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Kein Ort'),
                ),
                ...locations.map(
                  (l) => DropdownMenuItem<int?>(
                    value: l.id,
                    child: Text(l.name),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _locationId = value),
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              leading: const Icon(Icons.event_outlined),
              title: Text(
                _expiryDate == null
                    ? 'Kein Ablaufdatum'
                    : 'Läuft ab am ${DateFormat('dd.MM.yyyy').format(_expiryDate!)}',
              ),
              trailing: _expiryDate == null
                  ? const Icon(Icons.add)
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Datum entfernen',
                      onPressed: () => setState(() => _expiryDate = null),
                    ),
              onTap: _pickExpiryDate,
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
