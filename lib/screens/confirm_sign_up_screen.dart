import 'package:material_ui/material_ui.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class ConfirmSignUpScreen extends StatefulWidget {
  const ConfirmSignUpScreen({
    super.key,
    required this.email,
  });

  final String email;

  @override
  State<ConfirmSignUpScreen> createState() => _ConfirmSignUpScreenState();
}

class _ConfirmSignUpScreenState extends State<ConfirmSignUpScreen> {
  final _codeController = TextEditingController();

  bool _isConfirming = false;
  bool _isResending = false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Future<void> _confirmCode() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      _showMessage('Enter the code from your email.');
      return;
    }

    setState(() {
      _isConfirming = true;
    });

    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: widget.email,
        confirmationCode: code,
      );

      if (!mounted) return;

      if (result.nextStep.signUpStep == AuthSignUpStep.done) {
        final messenger = ScaffoldMessenger.of(context);

        // Return to the login screen.
        Navigator.of(context).popUntil((route) => route.isFirst);

        messenger.showSnackBar(
          const SnackBar(
            content: Text('Email confirmed. You can now sign in.'),
          ),
        );
      } else {
        _showMessage('More confirmation is required.');
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isResending = true;
    });

    try {
      await Amplify.Auth.resendSignUpCode(
        username: widget.email,
      );

      if (!mounted) return;
      _showMessage('A new confirmation code was sent.');
    } on AuthException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Widget _verificationCodeInput() {
    return Semantics(
      label: 'Six-digit email confirmation code',
      textField: true,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _codeController,
        builder: (context, value, _) {
          final code = value.text;

          return SizedBox(
            height: 56,
            child: Stack(
              children: [
                Row(
                  children: List.generate(6, (index) {
                    final digit = index < code.length ? code[index] : '';
                    final isActiveBox = index == code.length && code.length < 6;

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index == 5 ? 0 : 8,
                        ),
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActiveBox
                                  ? Theme.of(context).colorScheme.primary
                                  : const Color(0xFFB8C4C0),
                              width: isActiveBox ? 2 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            digit,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                // This real text field receives keyboard input.
                // The six boxes above display the entered digits.
                Positioned.fill(
                  child: TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    maxLength: 6,
                    style: const TextStyle(
                      color: Colors.transparent,
                    ),
                    cursorColor: Colors.transparent,
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Verify email'),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDDF5ED),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mail_outline,
                    size: 52,
                    color: Color(0xFF008577),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              Text(
                'Check your email',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Enter the 6-digit code we sent to',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 4),

              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 32),

              _verificationCodeInput(),
              const SizedBox(height: 32),

              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _isConfirming ? null : _confirmCode,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isConfirming
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Confirm email'),
                ),
              ),
              const SizedBox(height: 8),

              TextButton(
                onPressed: _isResending ? null : _resendCode,
                child: Text(
                  _isResending ? 'Sending code…' : 'Resend code',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
