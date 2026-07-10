import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/inventory_provider.dart';
import '../providers/settings_provider.dart';
import '../services/backup_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _change(
    BuildContext context, {
    int? warnDays,
    int? reminderDays,
    TimeOfDay? reminderTime,
  }) async {
    final settings = context.read<SettingsProvider>();
    final inventory = context.read<InventoryProvider>();
    await settings.update(
      warnDays: warnDays,
      reminderDays: reminderDays,
      reminderTime: reminderTime,
    );
    // Geänderte Zeiten gelten auch für bereits geplante Erinnerungen.
    await inventory.rescheduleAllNotifications();
  }

  Future<void> _pickTime(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final picked = await showTimePicker(
      context: context,
      initialTime: settings.reminderTime,
      helpText: 'Uhrzeit der Erinnerung',
    );
    if (picked != null && context.mounted) {
      await _change(context, reminderTime: picked);
    }
  }

  void _showMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _export(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    try {
      final data = await BackupService.instance.buildExport(settings.toJson());
      final bytes = Uint8List.fromList(
          utf8.encode(const JsonEncoder.withIndent('  ').convert(data)));
      final fileName =
          'inventar-backup-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json';
      final path = await FilePicker.saveFile(
        dialogTitle: 'Sicherung speichern',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: bytes,
      );
      if (path != null && context.mounted) {
        _showMessage(context, 'Sicherung gespeichert.');
      }
    } catch (e) {
      if (context.mounted) _showMessage(context, 'Export fehlgeschlagen: $e');
    }
  }

  Future<void> _import(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final inventory = context.read<InventoryProvider>();
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Sicherung auswählen',
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final bytes = file.bytes ?? await File(file.path!).readAsBytes();
      final data = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;

      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sicherung importieren?'),
          content: const Text(
              'Alle aktuellen Produkte, Fächer und Einstellungen werden '
              'durch den Inhalt der Sicherung ersetzt.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Importieren'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      final importedSettings = await BackupService.instance.restore(data);
      if (importedSettings != null) {
        await settings.applyJson(importedSettings);
      }
      await inventory.load();
      await inventory.rescheduleAllNotifications();
      if (context.mounted) _showMessage(context, 'Import abgeschlossen.');
    } on FormatException catch (e) {
      if (context.mounted) _showMessage(context, e.message);
    } catch (e) {
      if (context.mounted) _showMessage(context, 'Import fehlgeschlagen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        children: [
          const _SectionTitle('Anzeige'),
          _StepperTile(
            title: 'Orange anzeigen ab',
            subtitle: 'Produkte gelten so viele Tage vor Ablauf als '
                '„läuft bald ab“.',
            value: settings.warnDays,
            unit: 'Tage',
            min: 1,
            max: 90,
            onChanged: (value) => _change(context, warnDays: value),
          ),
          const Divider(),
          const _SectionTitle('Erinnerungen'),
          _StepperTile(
            title: 'Erinnerung vor Ablauf',
            subtitle: 'So viele Tage vor dem Ablaufdatum kommt die erste '
                'Benachrichtigung (0 = nur am Ablauftag).',
            value: settings.reminderDays,
            unit: 'Tage',
            min: 0,
            max: 90,
            onChanged: (value) => _change(context, reminderDays: value),
          ),
          ListTile(
            title: const Text('Uhrzeit der Erinnerung'),
            subtitle: const Text(
                'Am Ablauftag kommt zusätzlich immer eine Benachrichtigung.'),
            trailing: FilledButton.tonal(
              onPressed: () => _pickTime(context),
              child: Text(
                MaterialLocalizations.of(context).formatTimeOfDay(
                  settings.reminderTime,
                  alwaysUse24HourFormat: true,
                ),
              ),
            ),
            onTap: () => _pickTime(context),
          ),
          const Divider(),
          const _SectionTitle('Daten'),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Daten exportieren'),
            subtitle: const Text(
                'Sichert Produkte, Fächer und Einstellungen als JSON-Datei.'),
            onTap: () => _export(context),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Daten importieren'),
            subtitle: const Text(
                'Ersetzt die aktuellen Daten durch eine Sicherungsdatei.'),
            onTap: () => _import(context),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StepperTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final int value;
  final String unit;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _StepperTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Text(
            '$value $unit',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
