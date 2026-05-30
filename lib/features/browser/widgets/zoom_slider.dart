import 'package:flutter/material.dart';
import 'package:zoomview/core/constants.dart';
import 'package:zoomview/core/extensions.dart';

class ZoomSlider extends StatelessWidget {
  final double zoomLevel;
  final double minZoom;
  final double maxZoom;
  final ValueChanged<double> onChanged;

  const ZoomSlider({
    super.key,
    required this.zoomLevel,
    required this.minZoom,
    required this.maxZoom,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.zoomBg,
        border: Border(top: BorderSide(color: colors.border, width: 0.5)),
      ),
      padding: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 6 + bottomPadding),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              icon: Icon(Icons.zoom_out, size: 20, color: colors.fg2),
              onPressed: () {
                final newZoom =
                    (zoomLevel - AppConstants.zoomStep).clamp(minZoom, maxZoom);
                onChanged(double.parse(newZoom.toStringAsFixed(1)));
              },
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Slider(
              value: zoomLevel.clamp(minZoom, maxZoom),
              min: minZoom,
              max: maxZoom,
              divisions: ((maxZoom - minZoom) / AppConstants.zoomStep).round(),
              onChanged: (v) =>
                  onChanged(double.parse(v.toStringAsFixed(1))),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              icon: Icon(Icons.zoom_in, size: 20, color: colors.fg2),
              onPressed: () {
                final newZoom =
                    (zoomLevel + AppConstants.zoomStep).clamp(minZoom, maxZoom);
                onChanged(double.parse(newZoom.toStringAsFixed(1)));
              },
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 48,
            child: Text(
              '${(zoomLevel.clamp(minZoom, maxZoom) * 100).round()}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.fg,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
