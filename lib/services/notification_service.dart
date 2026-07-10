import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/product.dart';

/// Plant lokale Benachrichtigungen: eine Erinnerung 3 Tage vor Ablauf
/// und eine am Ablauftag, jeweils um 9:00 Uhr.
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _reminderDaysBefore = 3;
  static const _notificationHour = 9;

  Future<void> init() async {
    tz_data.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName.identifier));
    } catch (_) {
      // Fallback: UTC, falls die Zeitzone nicht gefunden wird.
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings: settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Plant beide Erinnerungen für ein Produkt neu (alte werden entfernt).
  Future<void> scheduleForProduct(Product product) async {
    final id = product.id;
    if (id == null) return;
    await cancelForProduct(id);

    final expiry = product.expiryDate;
    if (expiry == null) return;

    final reminderDate = DateTime(expiry.year, expiry.month,
        expiry.day - _reminderDaysBefore, _notificationHour);
    final expiryDate =
        DateTime(expiry.year, expiry.month, expiry.day, _notificationHour);

    await _schedule(
      notificationId: id * 10,
      when: reminderDate,
      title: 'Läuft bald ab: ${product.name}',
      body: 'Läuft in $_reminderDaysBefore Tagen ab.',
    );
    await _schedule(
      notificationId: id * 10 + 1,
      when: expiryDate,
      title: 'Heute abgelaufen: ${product.name}',
      body: 'Das Produkt sollte ersetzt werden.',
    );
  }

  Future<void> _schedule({
    required int notificationId,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    final scheduled = tz.TZDateTime.from(when, tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'expiry_channel',
          'Ablauf-Erinnerungen',
          channelDescription:
              'Erinnerungen an Produkte, die bald ablaufen oder abgelaufen sind',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelForProduct(int productId) async {
    await _plugin.cancel(id: productId * 10);
    await _plugin.cancel(id: productId * 10 + 1);
  }
}
