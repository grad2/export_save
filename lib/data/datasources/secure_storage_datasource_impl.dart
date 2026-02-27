import 'package:export_save/data/datasources/secure_storage_datasource.dart';
import 'package:export_save/domain/entities/rustfs_settings.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';



@Singleton(as: SecureStorageDataSource)
class SecureStorageDataSourceImpl extends SecureStorageDataSource{

  static const _keyRustFsAccess = 'rustfs_access_key';
  static const _keyRustFsSecret = 'rustfs_secret_key';
  static const _keyDbPath = 'db_path';
  static const _keyRustFsUrl = 'rustfs_url';

  final FlutterSecureStorage _storage;

  SecureStorageDataSourceImpl(this._storage);


  @override
  Future<RustFsSettings> readSettings() async {
    final values = await _storage.readAll();
    return RustFsSettings(
      accessKey: values[_keyRustFsAccess] ?? '',
      secretKey: values[_keyRustFsSecret] ?? '',
      dbPath: values[_keyDbPath] ?? '',
      rustfsUrl: values[_keyRustFsUrl] ?? '',
    );
  }

  @override
  Future<void> saveSettings(RustFsSettings settings) async {
    await _storage.write(key: _keyRustFsAccess, value: settings.accessKey.trim());
    await _storage.write(key: _keyRustFsSecret, value: settings.secretKey.trim());
    await _storage.write(key: _keyDbPath, value: settings.dbPath.trim());
    await _storage.write(key: _keyRustFsUrl, value: settings.rustfsUrl.trim());
  }
}
