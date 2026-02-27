import 'dart:io';
import 'dart:typed_data';

import 'package:export_save/data/datasources/rustfs_datasource.dart';
import 'package:injectable/injectable.dart';
import 'package:minio/minio.dart';

import '../models/rustfs_connection.dart';

@Singleton(as: RustFsDataSource)
class RustFsDataSourceImpl extends RustFsDataSource{

  @override
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


    await minio.putObject(connection.bucket, objectName, Stream.value(file.readAsBytesSync()));

    final expiresAt = DateTime.now().add(validFor);
    final link = await minio.presignedGetObject(
      connection.bucket,
      objectName,
      expires: validFor.inSeconds,
    );

    return (link, objectName, expiresAt);
  }

  @override
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
