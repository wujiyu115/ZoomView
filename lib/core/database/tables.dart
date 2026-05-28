class Tables {
  Tables._();

  static const String bookmarkFolders = '''
    CREATE TABLE bookmark_folders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      parent_id INTEGER,
      sort_order INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      FOREIGN KEY (parent_id) REFERENCES bookmark_folders(id) ON DELETE CASCADE
    )
  ''';

  static const String bookmarks = '''
    CREATE TABLE bookmarks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      url TEXT NOT NULL,
      favicon BLOB,
      folder_id INTEGER,
      sort_order INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      FOREIGN KEY (folder_id) REFERENCES bookmark_folders(id) ON DELETE SET NULL
    )
  ''';

  static const String downloads = '''
    CREATE TABLE downloads (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      url TEXT NOT NULL,
      file_name TEXT NOT NULL,
      file_path TEXT NOT NULL,
      mime_type TEXT,
      total_bytes INTEGER NOT NULL DEFAULT 0,
      downloaded_bytes INTEGER NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'pending',
      created_at TEXT NOT NULL
    )
  ''';

  static const String history = '''
    CREATE TABLE history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      url TEXT NOT NULL,
      favicon BLOB,
      visited_at TEXT NOT NULL
    )
  ''';

  static const String settings = '''
    CREATE TABLE settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  ''';
}
