import 'package:material_ui/material_ui.dart';
import 'package:buku555/data/currency_preferences.dart';
import 'package:buku555/screens/auth_gate.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'amplify_outputs.dart';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF3F6F4),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F6F4),
      ),
      home: const AuthGate(),
    );
  }
}
