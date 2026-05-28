import 'dart:typed_data';

class Bookmark {
  final int? id;
  final String title;
  final String url;
  final Uint8List? favicon;
  final int? folderId;
  final int sortOrder;
  final DateTime createdAt;

  Bookmark({
    this.id,
    required this.title,
    required this.url,
    this.favicon,
    this.folderId,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'] as int?,
      title: map['title'] as String,
      url: map['url'] as String,
      favicon: map['favicon'] as Uint8List?,
      folderId: map['folder_id'] as int?,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'url': url,
      'favicon': favicon,
      'folder_id': folderId,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
