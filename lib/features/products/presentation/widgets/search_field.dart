import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';


class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const SearchField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: width),
    );

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          textInputAction: TextInputAction.search,
          cursorColor: c.accentFg,
          style: TextStyle(color: c.ink, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Search products',
            hintStyle: TextStyle(color: c.subtle),
            filled: true,
            fillColor: c.field,
            prefixIcon: Icon(Icons.search, color: c.subtle),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    onPressed: onClear,
                    tooltip: 'Clear search',
                    icon: Icon(Icons.close, color: c.subtle),
                  ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: border(Colors.transparent, 0),
            enabledBorder: border(Colors.transparent, 0),
            focusedBorder: border(c.accentFg, 1.5),
          ),
        );
      },
    );
  }
}
