import 'package:buku555/screens/navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:buku555/data/currency_preferences.dart';
import 'package:buku555/data/theme_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await CurrencyPreferences.instance.load();
  await CurrencyPreferences.instance.load();
  await ThemePreferences.instance.load();

  runApp(const Buku555());
}

class Buku555 extends StatelessWidget {
  const Buku555({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemePreferences.instance.current,
      builder: (context, themeMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.white,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: Brightness.dark,
            ),
          ),
          home: const NavigationScreen(),
        );
      },
    );
  }
}
