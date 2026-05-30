import 'package:flutter/cupertino.dart';
import 'package:zoomview/core/extensions.dart';

class IosToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const IosToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoSwitch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: context.appColors.accent,
    );
  }
}
