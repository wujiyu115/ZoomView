import 'dart:typed_data';

class HistoryModel {
  final int? id;
  final String title;
  final String url;
  final Uint8List? favicon;
  final DateTime visitedAt;

  HistoryModel({
    this.id,
    required this.title,
    required this.url,
    this.favicon,
    DateTime? visitedAt,
  }) : visitedAt = visitedAt ?? DateTime.now();

  factory HistoryModel.fromMap(Map<String, dynamic> map) {
    return HistoryModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      url: map['url'] as String,
      favicon: map['favicon'] as Uint8List?,
      visitedAt: DateTime.parse(map['visited_at'] as String),
    );
  }
}
