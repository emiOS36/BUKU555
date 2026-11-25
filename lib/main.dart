import 'package:material_ui/material_ui.dart';
import 'package:buku555/data/currency_preferences.dart';
import 'package:buku555/screens/auth_gate.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'amplify_outputs.dart';

const _pageBackground = Color(0xFFF3F6F4);
const _brandTeal = Color(0xFF008577);
const _fieldOutlineTeal = Color(0xFF9ADBD2);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await CurrencyPreferences.instance.load();
  await Amplify.addPlugin(AmplifyAuthCognito());
  await Amplify.configure(amplifyConfig);

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
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: _brandTeal,
              brightness: Brightness.light,
            ).copyWith(
              primary: _brandTeal,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
        scaffoldBackgroundColor: _pageBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: _pageBackground,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: const InputDecorationThemeData(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(
              color: _fieldOutlineTeal,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(
              color: _brandTeal,
              width: 1.5,
            ),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}
