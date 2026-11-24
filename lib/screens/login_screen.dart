import 'package:material_ui/material_ui.dart';
import 'package:flutter/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _hidePassword = true;

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

  InputDecoration _fieldDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    final colors = Theme.of(context).colorScheme;

    return InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: .circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF9ADBD2),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: .circular(14),
        borderSide: BorderSide(
          color: colors.primary,
          width: 1.5,
        ),
      ),
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
      backgroundColor: const Color(0xFFF3F6F4),
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
              const SizedBox(height: 48),

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
                    backgroundColor: const Color(0xFF008577),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: .circular(14),
                    ),
                  ),
                  onPressed: () {
                    _showPlaceHolderMessage(
                      'Sign-in will work after Congnito is connected.',
                    );
                  },
                  child: const Text(
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
                      _showPlaceHolderMessage(
                        'Account creation will be connected to Cognito later.',
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
