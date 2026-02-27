
import 'package:export_save/domain/entities/rustfs_settings.dart';

abstract class SecureStorageDataSource {

  Future<RustFsSettings> readSettings();

  Future<void> saveSettings(RustFsSettings settings);
}
