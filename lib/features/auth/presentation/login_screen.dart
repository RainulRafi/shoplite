import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import 'auth_provider.dart';

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

  bool _hidePassword = true;
  bool _submitting = false;
  ApiException? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
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

    final error = await auth.signIn(_username.text, _password.text);
    if (!mounted) return;

    if (error == null) {
      TextInput.finishAutofillContext();
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _submitting = false;
        _error = error;
      });
    }
  }

  void _fillDemo() {
    _username.text = 'emilys';
    _password.text = 'emilyspass';
    setState(() => _error = null);
  }

  InputDecoration _decoration(AppColors c, {String? hint, Widget? suffix}) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: width),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: c.subtle),
      filled: true,
      fillColor: c.field,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(Colors.transparent, 0),
      enabledBorder: border(Colors.transparent, 0),
      focusedBorder: border(c.accentFg, 1.5),
      errorBorder: border(c.danger, 1),
      focusedErrorBorder: border(c.danger, 1.5),
      errorStyle: TextStyle(color: c.danger, fontSize: 13),
    );
  }

  Widget _label(String text, AppColors c) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: c.muted,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        backgroundColor: c.bg,
        appBar: AppBar(
          backgroundColor: c.bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: 'Close',
            icon: Icon(Icons.close, color: c.ink),
            onPressed: _submitting
                ? null
                : () => Navigator.of(context).pop(false),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                'Sign in',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
              if (widget.reason != null) ...[
                const SizedBox(height: 6),
                Text(
                  widget.reason!,
                  style: TextStyle(fontSize: 15, height: 1.4, color: c.muted),
                ),
              ],
              const SizedBox(height: 28),

              Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Username', c),
                      TextFormField(
                        controller: _username,
                        enabled: !_submitting,
                        autofillHints: const [AutofillHints.username],
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                        style: TextStyle(color: c.ink, fontSize: 15),
                        decoration: _decoration(c),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter your username'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      _label('Password', c),
                      TextFormField(
                        controller: _password,
                        enabled: !_submitting,
                        obscureText: _hidePassword,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        autocorrect: false,
                        enableSuggestions: false,
                        onFieldSubmitted: (_) => _submit(),
                        style: TextStyle(color: c.ink, fontSize: 15),
                        decoration: _decoration(
                          c,
                          suffix: IconButton(
                            tooltip: _hidePassword
                                ? 'Show password'
                                : 'Hide password',
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: c.subtle,
                            ),
                            onPressed: () =>
                                setState(() => _hidePassword = !_hidePassword),
                          ),
                        ),

                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Enter your password'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 14),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!.message,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: c.danger,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),

              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: c.onAccent,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                child: Text(_submitting ? 'Signing in...' : 'Sign in'),
              ),
              const SizedBox(height: 8),

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
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This is a practice app. Sign in with the test account '
                      'emilys / emilyspass.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: c.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: _submitting ? null : _fillDemo,
                      style: TextButton.styleFrom(
                        foregroundColor: c.accentFg,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 48),
                        alignment: Alignment.centerLeft,
                      ),
                      child: const Text('Use test account'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
