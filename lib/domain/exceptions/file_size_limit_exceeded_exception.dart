class FileSizeLimitExceededException implements Exception {
  const FileSizeLimitExceededException({required this.maxBytes, required this.actualBytes});

  final int maxBytes;
  final int actualBytes;
}
