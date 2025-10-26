import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String hintText;
  final Widget? suffixIcon;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.hintText = 'Search...',
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
      ),
    );
  }
}
