import 'package:buku555/screens/navigation_screen.dart';
import 'package:flutter/material.dart';

void main() {
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
      ),
      home: NavigationScreen(),
    );
  }
}
