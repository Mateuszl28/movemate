import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'history_screen.dart';
import 'home_screen.dart';
import 'notification_service.dart';
import 'onboarding_screen.dart';
import 'settings_screen.dart';
import 'storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_US', null);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  final storage = await Storage.open();
  await NotificationService.instance.init();
  await NotificationService.instance
      .scheduleReminders(storage.reminderIntervalHours);
  runApp(MoveMateApp(storage: storage));
}

class MoveMateApp extends StatefulWidget {
  final Storage storage;
  const MoveMateApp({super.key, required this.storage});

  @override
  State<MoveMateApp> createState() => _MoveMateAppState();
}

class _MoveMateAppState extends State<MoveMateApp> {
  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2EB872),
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2EB872),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'MoveMate',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(lightScheme),
      darkTheme: _buildTheme(darkScheme),
      home: !widget.storage.onboarded
          ? OnboardingScreen(
              storage: widget.storage,
              onDone: () => setState(() {}),
            )
          : AppShell(storage: widget.storage),
    );
  }

  ThemeData _buildTheme(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: scheme.onSurface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        elevation: 1,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: scheme.onSurface,
          ),
        ),
      ),
      textTheme: Typography.englishLike2021.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  final Storage storage;
  const AppShell({super.key, required this.storage});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _reminderShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowReminder());
  }

  void _maybeShowReminder() {
    if (_reminderShown || !mounted) return;
    final sessions = widget.storage.sessions;
    if (sessions.isEmpty) return;
    final last = sessions.first.completedAt;
    final hours = widget.storage.reminderIntervalHours;
    final since = DateTime.now().difference(last);
    if (since >= Duration(hours: hours)) {
      _reminderShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
          content: const Text(
            '⏰ Time to move! Do a quick 2–3 min session.',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
          ),
          action: SnackBarAction(
            label: 'Start',
            textColor: Colors.white,
            onPressed: () => setState(() => _index = 0),
          ),
        ),
      );
    }
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(
        storage: widget.storage,
        onSessionComplete: _refresh,
      ),
      HistoryScreen(storage: widget.storage),
      SettingsScreen(storage: widget.storage, onChanged: _refresh),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.show_chart_outlined),
              selectedIcon: Icon(Icons.show_chart),
              label: 'Progress'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }
}
