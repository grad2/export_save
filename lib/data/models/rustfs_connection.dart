class RustFsConnection {
  const RustFsConnection({
    required this.endPoint,
    required this.bucket,
    required this.useSsl,
    required this.port,
    required this.accessKey,
    required this.secretKey,
  });

  factory RustFsConnection.fromUrl({
    required String rustfsUrl,
    required String accessKey,
    required String secretKey,
  }) {
    final uri = Uri.parse(rustfsUrl);
    final segments = uri.pathSegments.where((segment) => segment.isNotEmpty);
    final bucket = segments.isNotEmpty ? segments.first : 'saves';

    return RustFsConnection(
      endPoint: uri.host,
      bucket: bucket,
      useSsl: uri.scheme == 'https',
      port: uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80),
      accessKey: accessKey,
      secretKey: secretKey,
    );
  }

  final String endPoint;
  final String bucket;
  final bool useSsl;
  final int port;
  final String accessKey;
  final String secretKey;
}
