import 'package:flutter/material.dart';
import 'package:zoomview/core/constants.dart';

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
    return Container(
      color: Theme.of(context).appBarTheme.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              final newZoom =
                  (zoomLevel - AppConstants.zoomStep).clamp(minZoom, maxZoom);
              onChanged(double.parse(newZoom.toStringAsFixed(1)));
            },
          ),
          Expanded(
            child: Slider(
              value: zoomLevel,
              min: minZoom,
              max: maxZoom,
              divisions: ((maxZoom - minZoom) / AppConstants.zoomStep).round(),
              onChanged: (v) =>
                  onChanged(double.parse(v.toStringAsFixed(1))),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              final newZoom =
                  (zoomLevel + AppConstants.zoomStep).clamp(minZoom, maxZoom);
              onChanged(double.parse(newZoom.toStringAsFixed(1)));
            },
          ),
          SizedBox(
            width: 48,
            child: Text(
              '${(zoomLevel * 100).round()}%',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
