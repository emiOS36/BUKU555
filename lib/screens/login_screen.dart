import 'package:material_ui/material_ui.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:buku555/screens/navigation_screen.dart';
import 'package:buku555/screens/create_account_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _hidePassword = true;
  bool _isSigningIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showPlaceHolderMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showPlaceHolderMessage('Enter your email and password.');
      return;
    }

    setState(() {
      _isSigningIn = true;
    });

    try {
      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );

      if (!mounted) return;

      if (result.isSignedIn) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => const NavigationScreen(),
          ),
          (route) => false,
        );
      } else {
        _showPlaceHolderMessage(
          'More verification is needed to finish signing in.',
        );
      }
    } on AuthException catch (error) {
      if (!mounted) return;

      _showPlaceHolderMessage(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  InputDecoration _fieldDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    final colors = Theme.of(context).colorScheme;

    return InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon,
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: .w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: .circular(25),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: 104,
                    height: 104,
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 104,
                      height: 104,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Welcome',
                textAlign: .center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 32,
                  fontWeight: .w600,
                  letterSpacing: -0.5,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Sign in to your Buku555 account.',
                textAlign: .center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 36),

              _fieldLabel('Email'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: .next,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                decoration: _fieldDecoration(hint: 'Email address'),
              ),
              const SizedBox(height: 24),

              _fieldLabel('Password'),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _hidePassword,
                textInputAction: .done,
                autofillHints: const [AutofillHints.password],
                decoration: _fieldDecoration(
                  hint: 'Password',
                  suffixIcon: IconButton(
                    tooltip: _hidePassword ? 'Show password' : 'Hide password',
                    onPressed: () {
                      setState(() {
                        _hidePassword = !_hidePassword;
                      });
                    },
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),

              Align(
                alignment: .centerRight,
                child: TextButton(
                  onPressed: () {
                    _showPlaceHolderMessage(
                      'Password reset will be connected to Cognito Later.',
                    );
                  },
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: .circular(14),
                    ),
                  ),
                  onPressed: _isSigningIn ? null : _signIn,
                  child: _isSigningIn
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Sign in',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: .w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('New to Buku555?'),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CreateAccountScreen(),
                        ),
                      );
                    },
                    child: const Text('Create acccount'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
