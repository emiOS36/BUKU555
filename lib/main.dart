import 'package:buku555/screens/navigation_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:buku555/data/currency_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await CurrencyPreferences.instance.load();

  runApp(const Buku555());
}

class Buku555 extends StatelessWidget {
  const Buku555({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF3F6F4),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F6F4),
      ),
      home: const NavigationScreen(),
    );
  }
}
