import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/inventory_provider.dart';
import 'screens/locations_screen.dart';
import 'screens/overview_screen.dart';
import 'screens/product_form_screen.dart';
import 'screens/products_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();

  final provider = InventoryProvider();
  await provider.load();

  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: const InventarApp(),
    ),
  );
}

/// Dunkles Marineblau für die Kopfleiste (wie im Vorbild-Design).
const _navy = Color(0xFF1F3A5F);

class InventarApp extends StatelessWidget {
  const InventarApp({super.key});

  ThemeData _theme(Brightness brightness) => ThemeData(
        colorSchemeSeed: _navy,
        brightness: brightness,
        appBarTheme: const AppBarTheme(
          backgroundColor: _navy,
          foregroundColor: Colors.white,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventar',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      locale: const Locale('de'),
      supportedLocales: const [Locale('de')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  static const _titles = ['Übersicht', 'Produkte', 'Orte'];

  Widget? _fab(BuildContext context) {
    switch (_index) {
      case 1:
        return FloatingActionButton(
          tooltip: 'Produkt hinzufügen',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
          ),
          child: const Icon(Icons.add),
        );
      case 2:
        return FloatingActionButton(
          tooltip: 'Ort hinzufügen',
          onPressed: () => showLocationEditor(context),
          child: const Icon(Icons.add),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(
        index: _index,
        children: const [
          OverviewScreen(),
          ProductsScreen(),
          LocationsScreen(),
        ],
      ),
      floatingActionButton: _fab(context),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Übersicht',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Produkte',
          ),
          NavigationDestination(
            icon: Icon(Icons.place_outlined),
            selectedIcon: Icon(Icons.place),
            label: 'Orte',
          ),
        ],
      ),
    );
  }
}
