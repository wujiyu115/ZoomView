import 'package:flutter/material.dart';
import 'package:zoomview/core/extensions.dart';

class SearchBarWidget extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool pill;

  const SearchBarWidget({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.pill = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (pill) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 18, color: colors.muted),
            const SizedBox(width: 10),
            Text(hint, style: TextStyle(fontSize: 15, color: colors.muted)),
          ],
        ),
      );
    }

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: colors.urlBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: TextStyle(fontSize: 15, color: colors.fg),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 15, color: colors.muted),
          prefixIcon: Icon(Icons.search, size: 16, color: colors.muted),
          prefixIconConstraints: const BoxConstraints(minWidth: 36),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        ),
      ),
    );
  }
}
