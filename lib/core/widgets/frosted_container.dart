import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:zoomview/core/extensions.dart';

class FrostedContainer extends StatelessWidget {
  final Widget child;
  final bool showBottomBorder;

  const FrostedContainer({
    super.key,
    required this.child,
    this.showBottomBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.compose(
          outer: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          inner: ColorFilter.matrix(<double>[
            1.8, 0, 0, 0, 0,
            0, 1.8, 0, 0, 0,
            0, 0, 1.8, 0, 0,
            0, 0, 0, 1, 0,
          ]),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colors.toolbarBg,
            border: showBottomBorder
                ? Border(bottom: BorderSide(color: colors.border, width: 0.5))
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
