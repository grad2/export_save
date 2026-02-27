
import 'package:export_save/data/models/rustfs_connection.dart';

abstract class RustFsDataSource {

  Future<(String, String, DateTime)> uploadAndGetTempLink({
    required RustFsConnection connection,
    required String filePath,
    required Duration validFor,
  });

  Future<void> deleteObject({
    required RustFsConnection connection,
    required String objectName,
  });
}
