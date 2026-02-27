import 'dart:io';

import 'package:minio/minio.dart';

import '../models/rustfs_connection.dart';

class RustFsDataSource {
  const RustFsDataSource();

  Future<(String, String, DateTime)> uploadAndGetTempLink({
    required RustFsConnection connection,
    required String filePath,
    required Duration validFor,
  }) async {
    final file = File(filePath);
    final objectName =
        'exports/${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';

    final minio = Minio(
      endPoint: connection.endPoint,
      accessKey: connection.accessKey,
      secretKey: connection.secretKey,
      useSSL: connection.useSsl,
      port: connection.port,
    );

    await minio.putObject(connection.bucket, objectName, file.openRead());

    final expiresAt = DateTime.now().add(validFor);
    final link = await minio.presignedGetObject(
      connection.bucket,
      objectName,
      expires: validFor.inSeconds,
    );

    return (link, objectName, expiresAt);
  }

  Future<void> deleteObject({
    required RustFsConnection connection,
    required String objectName,
  }) async {
    final minio = Minio(
      endPoint: connection.endPoint,
      accessKey: connection.accessKey,
      secretKey: connection.secretKey,
      useSSL: connection.useSsl,
      port: connection.port,
    );

    await minio.removeObject(connection.bucket, objectName);
  }
}
