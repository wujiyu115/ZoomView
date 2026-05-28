class BookmarkFolder {
  final int? id;
  final String name;
  final int? parentId;
  final int sortOrder;
  final DateTime createdAt;

  BookmarkFolder({
    this.id,
    required this.name,
    this.parentId,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory BookmarkFolder.fromMap(Map<String, dynamic> map) {
    return BookmarkFolder(
      id: map['id'] as int?,
      name: map['name'] as String,
      parentId: map['parent_id'] as int?,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'parent_id': parentId,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
