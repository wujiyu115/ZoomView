enum DownloadStatus { pending, downloading, paused, completed, failed }

class DownloadModel {
  final int? id;
  final String url;
  final String fileName;
  final String filePath;
  final String? mimeType;
  final int totalBytes;
  final int downloadedBytes;
  final DownloadStatus status;
  final DateTime createdAt;

  DownloadModel({
    this.id,
    required this.url,
    required this.fileName,
    required this.filePath,
    this.mimeType,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.pending,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progressPercent =>
      totalBytes > 0 ? downloadedBytes / totalBytes : 0;

  factory DownloadModel.fromMap(Map<String, dynamic> map) {
    return DownloadModel(
      id: map['id'] as int?,
      url: map['url'] as String,
      fileName: map['file_name'] as String,
      filePath: map['file_path'] as String,
      mimeType: map['mime_type'] as String?,
      totalBytes: map['total_bytes'] as int? ?? 0,
      downloadedBytes: map['downloaded_bytes'] as int? ?? 0,
      status: DownloadStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String? ?? 'pending'),
        orElse: () => DownloadStatus.pending,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
