# Inventar-App

Eine Flutter-App für Android zur Verwaltung des eigenen Vorrats: Produkte erfassen, Lagerorte zuordnen und Ablaufdaten im Blick behalten. Die App zeigt, was als Nächstes abläuft und was ersetzt werden muss — inklusive Erinnerung per Benachrichtigung.

## Funktionen

- **Übersicht**: Produkte gruppiert nach Dringlichkeit
  - 🔴 Abgelaufen — sollte ersetzt werden
  - 🟠 Läuft in den nächsten 7 Tagen ab
  - 🟢 Demnächst fällig
- **Produkte** erfassen mit Name, Menge, Lagerort, Ablaufdatum und Notizen; Menge direkt in der Liste per +/− anpassen; Suche
- **Orte** verwalten (z. B. Kühlschrank, Keller, Vorratsschrank) — anlegen, umbenennen, löschen
- **Benachrichtigungen**: Erinnerung 3 Tage vor Ablauf und am Ablauftag (jeweils 9:00 Uhr), auch nach einem Geräte-Neustart
- **Offline & privat**: alle Daten liegen lokal in einer SQLite-Datenbank auf dem Gerät, kein Konto nötig
- Deutsche Oberfläche, helles und dunkles Design (Material 3)

## Technik

| Bereich | Lösung |
|---|---|
| Framework | Flutter (Dart), Ziel-Plattform Android |
| Datenhaltung | [sqflite](https://pub.dev/packages/sqflite) (SQLite) |
| State-Management | [provider](https://pub.dev/packages/provider) |
| Benachrichtigungen | [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) + [timezone](https://pub.dev/packages/timezone) |
| Datums-/Zahlenformate | [intl](https://pub.dev/packages/intl) |

## Projektstruktur

```
lib/
├── main.dart                        # App-Start, Theme, Navigation (3 Tabs)
├── models/
│   ├── product.dart                 # Produkt inkl. Ablauf-Status-Logik
│   └── location.dart                # Lagerort
├── providers/
│   └── inventory_provider.dart      # App-Zustand, CRUD, Benachrichtigungs-Planung
├── services/
│   ├── database_service.dart        # SQLite (Tabellen, Abfragen)
│   └── notification_service.dart    # Lokale Erinnerungen planen/aufheben
├── screens/
│   ├── overview_screen.dart         # Übersicht nach Dringlichkeit
│   ├── products_screen.dart         # Produktliste mit Suche
│   ├── product_form_screen.dart     # Produkt anlegen/bearbeiten/löschen
│   └── locations_screen.dart        # Orte verwalten
└── widgets/
    └── product_tile.dart            # Produkt-Kachel mit Status-Farbe
```

## Voraussetzungen

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (getestet mit Flutter 3.41)
- Android SDK (über Android Studio oder `sdkmanager`)
- Zum Ausführen: ein Android-Gerät mit USB-Debugging **oder** ein Android-Emulator

## Bauen & Ausführen

```bash
# Abhängigkeiten holen
flutter pub get

# Auf angeschlossenem Gerät/Emulator starten
flutter run

# Debug-APK bauen
flutter build apk --debug

# Release-APK bauen (benötigt eigene Signierung für den Play Store)
flutter build apk --release
```

Die fertige APK liegt danach unter `build/app/outputs/flutter-apk/`.

## Tests

```bash
flutter test      # Unit-Tests (Ablauf-Logik, Serialisierung)
flutter analyze   # Statische Analyse
```

## Hinweise zu Benachrichtigungen

- Beim ersten Start fragt die App die Benachrichtigungs-Berechtigung ab (Android 13+).
- Erinnerungen werden mit inexaktem Zeitplan geplant (`inexactAllowWhileIdle`) — das schont den Akku und benötigt keine Sonderberechtigung; die Zustellung kann sich systembedingt um einige Minuten verschieben.
- Nach einem Neustart des Geräts stellt ein Boot-Receiver die geplanten Erinnerungen wieder her.
