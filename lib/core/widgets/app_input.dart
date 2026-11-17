import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class FieldLabel extends StatelessWidget {
  final String text;

  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.colors.muted,
        ),
      ),
    );
  }
}

InputDecoration appInputDecoration(
  BuildContext context, {
  String? hint,
  Widget? suffix,
  String? helper,
}) {
  final c = context.colors;

  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: color, width: width),
  );

  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: c.subtle),
    helperText: helper,
    helperMaxLines: 3,
    helperStyle: TextStyle(color: c.faint, fontSize: 13),
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
