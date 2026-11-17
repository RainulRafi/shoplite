import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_input.dart';
import '../domain/profile_validators.dart';
import 'profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _first;
  late final TextEditingController _last;
  late final TextEditingController _phone;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileProvider>().effective;
    _first = TextEditingController(text: p?.firstName ?? '');
    _last = TextEditingController(text: p?.lastName ?? '');
    _phone = TextEditingController(text: p?.phone ?? '');
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ProfileProvider>();
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await provider.save(
      firstName: _first.text,
      lastName: _last.text,
      phone: _phone.text,
    );
    if (!mounted) return;

    switch (result) {
      case ProfileResult.saved:
        Navigator.of(context).pop(true);
      case ProfileResult.notSignedIn:
        Navigator.of(context).pop(false);
      case ProfileResult.invalid:
        setState(() {
          _saving = false;
          _error = 'Please check the highlighted fields.';
        });
      case ProfileResult.failed:
        setState(() {
          _saving = false;
          _error = 'Could not save your changes. Please try again.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final profile = context.watch<ProfileProvider>().effective;

    return PopScope(
      canPop: !_saving,
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
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          ),
          centerTitle: false,
          title: Text(
            'Edit profile',
            style: TextStyle(
              color: c.ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                const FieldLabel('First name'),
                TextFormField(
                  controller: _first,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.givenName],
                  style: TextStyle(color: c.ink, fontSize: 15),
                  decoration: appInputDecoration(context),
                  validator: ProfileValidators.firstName,
                ),
                const SizedBox(height: 18),
                const FieldLabel('Last name (optional)'),
                TextFormField(
                  controller: _last,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.familyName],
                  style: TextStyle(color: c.ink, fontSize: 15),
                  decoration: appInputDecoration(context),
                  validator: ProfileValidators.lastName,
                ),
                const SizedBox(height: 18),
                const FieldLabel('Mobile number (optional)'),
                TextFormField(
                  controller: _phone,
                  enabled: !_saving,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
                  ],
                  onFieldSubmitted: (_) => _save(),
                  style: TextStyle(color: c.ink, fontSize: 15),
                  decoration: appInputDecoration(context, hint: '01712345678'),
                  validator: ProfileValidators.phone,
                ),
                const SizedBox(height: 24),

                if (profile != null) ...[
                  _FixedRow(label: 'Username', value: profile.username),
                  if (profile.email.isNotEmpty)
                    _FixedRow(label: 'Email', value: profile.email),
                  const SizedBox(height: 8),
                ],
                Text(
                  'Your username and email belong to your account and cannot be changed '
                  'here. Name and number changes are saved on this phone only.',
                  style: TextStyle(fontSize: 13, height: 1.4, color: c.faint),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.danger,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                FilledButton(
                  onPressed: _saving ? null : _save,
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
                  child: Text(_saving ? 'Saving...' : 'Save changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FixedRow extends StatelessWidget {
  final String label;
  final String value;

  const _FixedRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: TextStyle(fontSize: 14, color: c.muted)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 14, color: c.ink)),
          ),
        ],
      ),
    );
  }
}
