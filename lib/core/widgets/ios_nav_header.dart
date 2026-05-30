import 'package:flutter/material.dart';
import 'package:zoomview/core/extensions.dart';

class IosNavHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  final Widget? trailing;
  final bool largeTitle;

  const IosNavHeader({
    super.key,
    required this.title,
    this.showBack = true,
    this.trailing,
    this.largeTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (largeTitle) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: colors.fg,
                  letterSpacing: -0.02 * 28,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          if (showBack)
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.maybePop(context),
                icon: Icon(Icons.arrow_back_ios_new, size: 22, color: colors.accent),
              ),
            ),
          Expanded(
            child: Text(
              title,
              textAlign: showBack ? TextAlign.center : TextAlign.start,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colors.fg,
              ),
            ),
          ),
          if (trailing != null)
            trailing!
          else if (showBack)
            const SizedBox(width: 44),
        ],
      ),
    );
  }
}
