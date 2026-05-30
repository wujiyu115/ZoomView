import 'package:flutter/material.dart';
import 'package:zoomview/core/extensions.dart';

class GroupedCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;

  const GroupedCard({
    super.key,
    required this.children,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(height: 0.5, thickness: 0.5, color: colors.border, indent: 16),
          ],
        ],
      ),
    );
  }
}
