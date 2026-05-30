import 'package:flutter/material.dart';
import 'package:zoomview/core/extensions.dart';

class SectionHeader extends StatelessWidget {
  final String label;
  final bool useAccentColor;

  const SectionHeader({
    super.key,
    required this.label,
    this.useAccentColor = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: useAccentColor ? colors.accent : colors.muted,
          letterSpacing: 0.04 * 13,
        ),
      ),
    );
  }
}
