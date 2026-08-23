/// 图片引用模型
class ImageRef {
  final String id;
  final String path;       // 本地文件路径
  final String? thumbnail; // 缩略图路径（可选）

  ImageRef({
    required this.id,
    required this.path,
    this.thumbnail,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'thumbnail': thumbnail,
      };

  factory ImageRef.fromJson(Map<String, dynamic> json) => ImageRef(
        id: json['id'] as String,
        path: json['path'] as String,
        thumbnail: json['thumbnail'] as String?,
      );
}
