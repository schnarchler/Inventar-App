import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart' show expiryWarnDays;
import '../services/notification_service.dart';

/// Vom Nutzer einstellbare Werte: Orange-Schwelle und Erinnerungszeitpunkt.
class SettingsProvider extends ChangeNotifier {
  static const _kWarnDays = 'warnDays';
  static const _kReminderDays = 'reminderDays';
  static const _kReminderHour = 'reminderHour';
  static const _kReminderMinute = 'reminderMinute';

  /// Ab wie vielen Tagen vor Ablauf orange angezeigt wird.
  int warnDays = 7;

  /// Wie viele Tage vor Ablauf die Erinnerung kommt (0 = nur am Ablauftag).
  int reminderDays = 3;

  /// Uhrzeit der Erinnerung.
  TimeOfDay reminderTime = const TimeOfDay(hour: 9, minute: 0);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    warnDays = prefs.getInt(_kWarnDays) ?? warnDays;
    reminderDays = prefs.getInt(_kReminderDays) ?? reminderDays;
    reminderTime = TimeOfDay(
      hour: prefs.getInt(_kReminderHour) ?? reminderTime.hour,
      minute: prefs.getInt(_kReminderMinute) ?? reminderTime.minute,
    );
    _apply();
  }

  Future<void> update({
    int? warnDays,
    int? reminderDays,
    TimeOfDay? reminderTime,
  }) async {
    this.warnDays = warnDays ?? this.warnDays;
    this.reminderDays = reminderDays ?? this.reminderDays;
    this.reminderTime = reminderTime ?? this.reminderTime;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kWarnDays, this.warnDays);
    await prefs.setInt(_kReminderDays, this.reminderDays);
    await prefs.setInt(_kReminderHour, this.reminderTime.hour);
    await prefs.setInt(_kReminderMinute, this.reminderTime.minute);

    _apply();
    notifyListeners();
  }

  void _apply() {
    expiryWarnDays = warnDays;
    NotificationService.instance.configure(
      reminderDaysBefore: reminderDays,
      hour: reminderTime.hour,
      minute: reminderTime.minute,
    );
  }
}
