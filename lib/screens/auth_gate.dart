import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:buku555/screens/login_screen.dart';
import 'package:buku555/screens/navigation_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<bool> _sessionCheck;

  @override
  void initState() {
    super.initState();
    _sessionCheck = _checkSession();
  }

  Future<bool> _checkSession() async {
    final session = await Amplify.Auth.fetchAuthSession();
    return session.isSignedIn;
  }

  void _retrySessionCheck() {
    setState(() {
      _sessionCheck = _checkSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _sessionCheck,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Could not check your sign-in status. '
                        'Check your connection and try again.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _retrySessionCheck,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.data == true) {
          return const NavigationScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
