class ImageUploadInput {
  const ImageUploadInput({
    required this.path,
    required this.fileName,
    this.mimeType,
  });

  final String path;
  final String fileName;
  final String? mimeType;

  String get extension {
    final name = fileName.toLowerCase();
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == name.length - 1) {
      return '';
    }
    return name.substring(dotIndex + 1);
  }
}
