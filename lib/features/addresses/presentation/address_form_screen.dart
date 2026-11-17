import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_input.dart';
import '../../profile/presentation/profile_provider.dart';
import '../domain/address.dart';
import '../domain/address_validators.dart';
import '../domain/bd_divisions.dart';
import 'address_provider.dart';

// নতুন Address বা সম্পাদনা। সংরক্ষণ হলে Navigator থেকে true ফেরত দেয়
class AddressFormScreen extends StatefulWidget {
  final Address? editing;

  const AddressFormScreen({super.key, this.editing});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _district;
  late final TextEditingController _area;
  late final TextEditingController _line1;
  late final TextEditingController _postal;
  late final TextEditingController _note;

  late AddressLabel _label;
  String? _division;
  late bool _isDefault;

  // ডিফল্ট চিহ্ন খুলে ফেলা যায় না: ডিফল্ট Address-এ, বা প্রথম Address-এ
  late final bool _defaultLocked;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final a = widget.editing;

    // নতুন Address-এ নাম আর ফোন প্রোফাইল থেকে আগে ভরা (ব্যবহারকারীর কাজ কম)
    final profile = a == null
        ? context.read<ProfileProvider>().effective
        : null;

    _name = TextEditingController(text: a?.fullName ?? profile?.fullName ?? '');
    _phone = TextEditingController(text: a?.phone ?? profile?.phone ?? '');
    _district = TextEditingController(text: a?.district ?? '');
    _area = TextEditingController(text: a?.area ?? '');
    _line1 = TextEditingController(text: a?.line1 ?? '');
    _postal = TextEditingController(text: a?.postalCode ?? '');
    _note = TextEditingController(text: a?.note ?? '');

    _label = a?.label ?? AddressLabel.home;
    _division = a?.division;

    final isFirst = context.read<AddressProvider>().addresses.isEmpty;
    _defaultLocked = (a?.isDefault ?? false) || (a == null && isFirst);
    _isDefault = _defaultLocked || (a?.isDefault ?? false);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _district.dispose();
    _area.dispose();
    _line1.dispose();
    _postal.dispose();
    _note.dispose();
    super.dispose();
  }

  String? _emptyToNull(String text) {
    final v = text.trim();
    return v.isEmpty ? null : v;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AddressProvider>();
    final draft = Address(
      id: widget.editing?.id,
      label: _label,
      fullName: _name.text.trim(),
      phone: _phone.text.trim(),
      division: _division!,
      district: _district.text.trim(),
      area: _area.text.trim(),
      line1: _line1.text.trim(),
      postalCode: _emptyToNull(_postal.text),
      note: _emptyToNull(_note.text),
      isDefault: _isDefault,
      updatedAt: DateTime.now(),
    );

    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await provider.save(draft);
    if (!mounted) return;

    switch (result) {
      case AddressResult.saved:
        Navigator.of(context).pop(true);
      case AddressResult.invalid:
        setState(() {
          _saving = false;
          _error = 'Please check the highlighted fields.';
        });
      case AddressResult.limitReached:
        setState(() {
          _saving = false;
          _error =
              'You can save up to ${AddressValidators.maxAddresses} addresses.';
        });
      case AddressResult.notSignedIn:
        Navigator.of(context).pop(false);
      case AddressResult.failed:
        setState(() {
          _saving = false;
          _error = 'Could not save the address. Please try again.';
        });
    }
  }

  Widget _labelPicker(AppColors c) {
    return Row(
      children: [
        for (final label in AddressLabel.values) ...[
          Expanded(
            child: Semantics(
              button: true,
              selected: _label == label,
              label: label.title,
              child: GestureDetector(
                onTap: _saving ? null : () => setState(() => _label = label),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _label == label ? c.accent : c.surface,
                    border: Border.all(
                      color: _label == label ? c.accent : c.border,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    label.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _label == label ? c.onAccent : c.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (label != AddressLabel.values.last) const SizedBox(width: 8),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final editing = widget.editing != null;

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
            editing ? 'Edit address' : 'New address',
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
                const FieldLabel('Label'),
                _labelPicker(c),
                const SizedBox(height: 18),

                const FieldLabel('Full name'),
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  style: TextStyle(color: c.ink, fontSize: 15),
                  decoration: appInputDecoration(context),
                  validator: AddressValidators.name,
                ),
                const SizedBox(height: 18),

                const FieldLabel('Mobile number'),
                TextFormField(
                  controller: _phone,
                  enabled: !_saving,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
                  ],
                  style: TextStyle(color: c.ink, fontSize: 15),
                  decoration: appInputDecoration(context, hint: '01712345678'),
                  validator: AddressValidators.phone,
                ),
                const SizedBox(height: 18),

                const FieldLabel('Division'),
                DropdownButtonFormField<String>(
                  initialValue: _division,
                  isExpanded: true,
                  dropdownColor: c.surface,
                  style: TextStyle(color: c.ink, fontSize: 15),
                  icon: Icon(Icons.keyboard_arrow_down, color: c.subtle),
                  decoration: appInputDecoration(
                    context,
                    hint: 'Choose a division',
                  ),
                  items: [
                    for (final d in bdDivisions)
                      DropdownMenuItem(value: d, child: Text(d)),
                  ],
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => _division = v),
                  validator: AddressValidators.division,
                ),
                const SizedBox(height: 18),

                const FieldLabel('District'),
                TextFormField(
                  controller: _district,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: c.ink, fontSize: 15),
                  decoration: appInputDecoration(context),
                  validator: AddressValidators.district,
                ),
                const SizedBox(height: 18),

                const FieldLabel('Area or thana'),
                TextFormField(
                  controller: _area,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: c.ink, fontSize: 15),
                  decoration: appInputDecoration(context),
                  validator: AddressValidators.area,
                ),
                const SizedBox(height: 18),

                const FieldLabel('House, road, village'),
                TextFormField(
                  controller: _line1,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  autofillHints: const [AutofillHints.streetAddressLine1],
                  style: TextStyle(color: c.ink, fontSize: 15),
                  decoration: appInputDecoration(
                    context,
                    hint: 'House 12, Road 4',
                  ),
                  validator: AddressValidators.line1,
                ),
                const SizedBox(height: 18),

                const FieldLabel('Postal code (optional)'),
                TextFormField(
                  controller: _postal,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  autofillHints: const [AutofillHints.postalCode],
                  style: TextStyle(color: c.ink, fontSize: 15),
                  decoration: appInputDecoration(context),
                  validator: AddressValidators.postalCode,
                ),
                const SizedBox(height: 18),

                const FieldLabel('Delivery note (optional)'),
                TextFormField(
                  controller: _note,
                  enabled: !_saving,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  style: TextStyle(color: c.ink, fontSize: 15),
                  decoration: appInputDecoration(
                    context,
                    hint: 'Call at the gate',
                  ),
                  validator: AddressValidators.note,
                ),
                const SizedBox(height: 20),

                // ডিফল্ট চিহ্ন। তালা দেওয়া থাকলে কেন, নিচে লেখা
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Use as my default address',
                        style: TextStyle(fontSize: 15, color: c.ink),
                      ),
                    ),
                    Switch(
                      value: _isDefault,
                      onChanged: (_saving || _defaultLocked)
                          ? null
                          : (v) => setState(() => _isDefault = v),
                      activeThumbColor: Colors.white,
                      activeTrackColor: c.accent,
                      inactiveThumbColor: c.subtle,
                      inactiveTrackColor: c.track,
                    ),
                  ],
                ),
                if (_defaultLocked) ...[
                  const SizedBox(height: 4),
                  Text(
                    editing
                        ? 'To change your default, make a different address the default.'
                        : 'Your first address is saved as the default.',
                    style: TextStyle(fontSize: 13, height: 1.4, color: c.faint),
                  ),
                ],

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
                  child: Text(_saving ? 'Saving...' : 'Save address'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
