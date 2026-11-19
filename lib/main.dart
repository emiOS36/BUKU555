import 'package:buku555/screens/navigation_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:buku555/data/currency_preferences.dart';
import 'package:buku555/data/theme_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
              seedColor: const Color(0xFFF3F6F4),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF3F6F4),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFF3F6F4),
              brightness: Brightness.dark,
            ),
          ),
          home: const NavigationScreen(),
        );
      },
    );
  }
}
