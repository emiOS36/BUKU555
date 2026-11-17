import 'package:buku555/screens/navigation_screen.dart';
import 'package:flutter/material.dart';
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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: .fromSeed(seedColor: Colors.teal),
        scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      home: NavigationScreen(),
    );
  }
}
