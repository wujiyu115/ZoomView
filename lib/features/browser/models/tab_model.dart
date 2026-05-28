import 'dart:typed_data';
import 'package:uuid/uuid.dart';

class TabModel {
  final String id;
  final String url;
  final String title;
  final Uint8List? favicon;
  final double zoomLevel;
  final double scrollPosition;
  final bool isActive;
  final DateTime createdAt;

  TabModel({
    String? id,
    required this.url,
    this.title = '',
    this.favicon,
    this.zoomLevel = 1.0,
    this.scrollPosition = 0,
    this.isActive = false,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  TabModel copyWith({
    String? url,
    String? title,
    Uint8List? favicon,
    double? zoomLevel,
    double? scrollPosition,
    bool? isActive,
  }) {
    return TabModel(
      id: id,
      url: url ?? this.url,
      title: title ?? this.title,
      favicon: favicon ?? this.favicon,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
