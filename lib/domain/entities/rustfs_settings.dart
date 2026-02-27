class RustFsSettings {
  const RustFsSettings({
    required this.accessKey,
    required this.secretKey,
    required this.dbPath,
    required this.rustfsUrl,
  });

  final String accessKey;
  final String secretKey;
  final String dbPath;
  final String rustfsUrl;

  bool get isValid =>
      accessKey.trim().isNotEmpty &&
      secretKey.trim().isNotEmpty &&
      dbPath.trim().isNotEmpty &&
      rustfsUrl.trim().isNotEmpty;
}
