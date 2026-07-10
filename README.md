# Inventar-App

Eine Flutter-App für Android zur Verwaltung des eigenen Vorrats: Produkte erfassen, Fächern zuordnen und Ablaufdaten im Blick behalten. Die App zeigt, was als Nächstes abläuft und was ersetzt werden muss — inklusive Erinnerung per Benachrichtigung.

## Funktionen

- **Übersicht**: Produkte gruppiert nach Dringlichkeit
  - 🔴 Abgelaufen — sollte ersetzt werden
  - 🟠 Läuft in den nächsten 7 Tagen ab
  - 🟢 Demnächst fällig
- **Produkte** erfassen mit Name, Fach und Notizen; pro Produkt mehrere **Posten** mit eigener Menge und eigenem Ablaufdatum (z. B. 2 Stück bis März, 1 Stück bis Juli); Suche
- **Produktliste** gruppiert nach Fächern als farbige, aufklappbare Karten mit Mengen-Badges („Alle aufklappen/zuklappen“)
- **Fächer** verwalten (z. B. Kühlschrank, Keller, Vorratsschrank) mit frei wählbarer **Farbe** für bessere Übersicht
- **Benachrichtigungen**: Erinnerung vor dem Ablauf und am Ablauftag, auch nach einem Geräte-Neustart; Vorlauf und Uhrzeit in den **Einstellungen** frei wählbar (ebenso die Schwelle für die orange Warnung)
- **Export/Import**: alle Daten (Produkte, Fächer, Einstellungen) als JSON-Datei sichern und wiederherstellen — z. B. für Gerätewechsel oder den Umstieg auf die F-Droid-Version
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
│   ├── product.dart                 # Produkt + Posten (Batch) inkl. Ablauf-Status-Logik
│   └── location.dart                # Fach mit Farbe
├── providers/
│   ├── inventory_provider.dart      # App-Zustand, CRUD, Benachrichtigungs-Planung
│   └── settings_provider.dart       # Einstellungen (Warn-Schwelle, Erinnerungszeit)
├── services/
│   ├── database_service.dart        # SQLite (Tabellen, Abfragen, Migrationen)
│   └── notification_service.dart    # Lokale Erinnerungen planen/aufheben
├── screens/
│   ├── overview_screen.dart         # Übersicht mit Dashboard, nach Dringlichkeit
│   ├── products_screen.dart         # Produkte gruppiert nach Fächern (farbige Karten)
│   ├── product_form_screen.dart     # Produkt anlegen/bearbeiten, Posten verwalten
│   ├── locations_screen.dart        # Fächer verwalten inkl. Farbauswahl
│   └── settings_screen.dart         # Einstellungen
└── widgets/
    └── product_tile.dart            # Produktzeile, Mengen-Badge, Fach-Chip, Farb-Helfer
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

# Release-APKs bauen (eine pro Prozessor-Architektur, ~20 MB statt ~55 MB)
flutter build apk --release --split-per-abi
```

Die fertigen APKs liegen danach unter `build/app/outputs/flutter-apk/`. Für die meisten aktuellen Geräte ist `app-arm64-v8a-release.apk` die richtige Datei.

## Release-Signierung & Veröffentlichung auf GitHub

Ohne eigene Signierung wird mit dem Debug-Schlüssel signiert (nur für lokale Tests geeignet). Für öffentliche Releases:

1. Einmalig einen Keystore erzeugen (Passwort wird interaktiv abgefragt, Datei **außerhalb** des Repos ablegen und sicher aufbewahren — ohne ihn sind keine Updates mehr möglich):

   ```bash
   mkdir -p ~/.android-keys
   keytool -genkey -v -keystore ~/.android-keys/inventar-release.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias inventar
   ```

2. `android/key.properties.example` nach `android/key.properties` kopieren und die Passwörter eintragen (die Datei ist von Git ausgeschlossen).

3. Bauen: `flutter build apk --release --split-per-abi` — die APKs sind jetzt mit deinem Schlüssel signiert.

4. Als GitHub-Release veröffentlichen:

   ```bash
   git tag v1.0.0 && git push --tags
   gh release create v1.0.0 build/app/outputs/flutter-apk/app-*-release.apk \
     --title "Inventar 1.0.0" --notes "Erste Version"
   ```

Hinweis: Die F-Droid-Version wird von F-Droid selbst signiert. Ein Wechsel zwischen GitHub-APK und F-Droid-Version erfordert eine Neuinstallation — vorher die Daten über Einstellungen → „Daten exportieren“ sichern.

## Tests

```bash
flutter test      # Unit-Tests (Ablauf-Logik, Serialisierung)
flutter analyze   # Statische Analyse
```

## Veröffentlichung auf F-Droid

Das Projekt erfüllt die F-Droid-Voraussetzungen: quelloffen ([MIT-Lizenz](LICENSE)), keine proprietären Abhängigkeiten (kein Google Play Services, kein Tracking), keine Internetberechtigung, alle Daten lokal. Die App-Beschreibung für den Store liegt im [Fastlane-Format](fastlane/metadata/android/de-DE/) bei und wird von F-Droid automatisch übernommen.

Schritte zur Veröffentlichung:

1. Repository öffentlich machen (z. B. GitHub, GitLab oder Codeberg) und pushen.
2. Ein Release taggen: `git tag v1.0.0 && git push --tags` (Version entspricht `version:` in `pubspec.yaml`).
3. Bei [fdroiddata](https://gitlab.com/fdroid/fdroiddata) einen Merge Request mit der Build-Beschreibung für `de.msu.inventar_app` erstellen — oder einfacher: eine [„Request for Packaging“ (RFP)](https://gitlab.com/fdroid/rfp/-/issues) eröffnen, dann übernimmt das F-Droid-Team die Aufnahme.
4. F-Droid baut die App aus dem Quellcode und signiert sie selbst; ein eigener Signaturschlüssel ist nicht nötig.

Hinweis: Die MIT-Lizenz kann vor der Veröffentlichung noch gegen z. B. GPL-3.0 getauscht werden — F-Droid akzeptiert beide. Im `LICENSE`-File ggf. den Namen des Rechteinhabers anpassen.

## Hinweise zu Benachrichtigungen

- Beim ersten Start fragt die App die Benachrichtigungs-Berechtigung ab (Android 13+).
- Erinnerungen werden mit inexaktem Zeitplan geplant (`inexactAllowWhileIdle`) — das schont den Akku und benötigt keine Sonderberechtigung; die Zustellung kann sich systembedingt um einige Minuten verschieben.
- Nach einem Neustart des Geräts stellt ein Boot-Receiver die geplanten Erinnerungen wieder her.
