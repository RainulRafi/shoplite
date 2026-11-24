import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_info.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_input.dart';
import 'auth_provider.dart';

const String _demoUsername = 'emilys';
const String _demoPassword = 'emilyspass';

class LoginScreen extends StatefulWidget {
  final String? reason;

  const LoginScreen({super.key, this.reason});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _fillDemo() {
    setState(() {
      _username.text = _demoUsername;
      _password.text = _demoPassword;
      _error = null;
    });
    _formKey.currentState?.validate();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });

    final failure = await auth.signIn(_username.text, _password.text);
    if (!mounted) return;

    if (failure == null) {
      TextInput.finishAutofillContext();
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _submitting = false;
      _error = failure.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Close',
                        icon: Icon(Icons.close, color: c.ink),
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        ExcludeSemantics(
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: c.accent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'S',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: c.onAccent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppInfo.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: c.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    Semantics(
                      header: true,
                      child: Text(
                        'Welcome back',
                        style: TextStyle(
                          fontSize: 30,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: c.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.reason ?? 'Sign in to continue.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: c.muted,
                      ),
                    ),
                    const SizedBox(height: 28),

                    AutofillGroup(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const FieldLabel('Username'),
                            TextFormField(
                              controller: _username,
                              enabled: !_submitting,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.username],
                              autocorrect: false,
                              enableSuggestions: false,
                              style: TextStyle(color: c.ink, fontSize: 16),
                              decoration: appInputDecoration(
                                context,
                                hint: 'Your username',
                              ),
                              validator: (v) => (v ?? '').trim().isEmpty
                                  ? 'Enter your username'
                                  : null,
                              onFieldSubmitted: (_) =>
                                  _passwordFocus.requestFocus(),
                            ),
                            const SizedBox(height: 18),

                            const FieldLabel('Password'),
                            TextFormField(
                              controller: _password,
                              focusNode: _passwordFocus,
                              enabled: !_submitting,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              autocorrect: false,
                              enableSuggestions: false,
                              style: TextStyle(color: c.ink, fontSize: 16),
                              decoration: appInputDecoration(
                                context,
                                hint: 'Your password',
                                suffix: IconButton(
                                  tooltip: _obscure
                                      ? 'Show password'
                                      : 'Hide password',
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: c.subtle,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) => (v ?? '').isEmpty
                                  ? 'Enter your password'
                                  : null,
                              onFieldSubmitted: (_) => _submit(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(
                      width: double.infinity,
                      child: _error == null
                          ? const SizedBox(height: 20)
                          : Padding(
                              padding: const EdgeInsets.only(
                                top: 16,
                                bottom: 4,
                              ),
                              child: Semantics(
                                liveRegion: true,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: c.danger),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _error!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      fontWeight: FontWeight.w600,
                                      color: c.danger,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),

                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: c.accent,
                        foregroundColor: c.onAccent,

                        disabledBackgroundColor: c.accent,
                        disabledForegroundColor: c.onAccent,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      child: _submitting
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: c.onAccent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text('Signing in...'),
                              ],
                            )
                          : const Text('Sign in'),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: c.accentFg,
                        minimumSize: const Size.fromHeight(48),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      child: const Text('Continue browsing'),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      decoration: BoxDecoration(
                        color: c.surface,
                        border: Border.all(color: c.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Demo account',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: c.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This practice app signs in to a public test server. '
                            'Use the demo account to try it.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: c.muted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Username: $_demoUsername\nPassword: $_demoPassword',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: c.ink,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: _submitting ? null : _fillDemo,
                              style: TextButton.styleFrom(
                                foregroundColor: c.accentFg,
                                minimumSize: const Size(64, 48),
                                padding: EdgeInsets.zero,
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              child: const Text('Fill in demo account'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Sign up and password reset are not available in this practice app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: c.faint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
