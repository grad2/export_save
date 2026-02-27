import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/rustfs_settings.dart';

class SecureStorageDataSource {
  const SecureStorageDataSource({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _keyRustFsAccess = 'rustfs_access_key';
  static const _keyRustFsSecret = 'rustfs_secret_key';
  static const _keyDbPath = 'db_path';
  static const _keyRustFsUrl = 'rustfs_url';

  final FlutterSecureStorage _storage;

  Future<RustFsSettings> readSettings() async {
    final values = await _storage.readAll();
    return RustFsSettings(
      accessKey: values[_keyRustFsAccess] ?? '',
      secretKey: values[_keyRustFsSecret] ?? '',
      dbPath: values[_keyDbPath] ?? '',
      rustfsUrl: values[_keyRustFsUrl] ?? '',
    );
  }

  Future<void> saveSettings(RustFsSettings settings) async {
    await _storage.write(key: _keyRustFsAccess, value: settings.accessKey.trim());
    await _storage.write(key: _keyRustFsSecret, value: settings.secretKey.trim());
    await _storage.write(key: _keyDbPath, value: settings.dbPath.trim());
    await _storage.write(key: _keyRustFsUrl, value: settings.rustfsUrl.trim());
  }
}
