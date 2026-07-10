import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/inventory_provider.dart';
import '../providers/settings_provider.dart';

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
