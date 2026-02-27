import '../../domain/entities/game_file.dart';
import '../../domain/entities/rustfs_settings.dart';
import '../../domain/entities/temp_link.dart';
import '../../domain/repositories/save_export_repository.dart';
import '../datasources/game_files_datasource.dart';
import '../datasources/rustfs_datasource.dart';
import '../datasources/secure_storage_datasource.dart';
import '../models/rustfs_connection.dart';

class SaveExportRepositoryImpl implements SaveExportRepository {
  const SaveExportRepositoryImpl({
    required SecureStorageDataSource secureStorageDataSource,
    required GameFilesDataSource gameFilesDataSource,
    required RustFsDataSource rustFsDataSource,
  }) : _secureStorageDataSource = secureStorageDataSource,
       _gameFilesDataSource = gameFilesDataSource,
       _rustFsDataSource = rustFsDataSource;

  final SecureStorageDataSource _secureStorageDataSource;
  final GameFilesDataSource _gameFilesDataSource;
  final RustFsDataSource _rustFsDataSource;

  @override
  Future<List<GameFile>> loadGames(String dbPath) {
    return _gameFilesDataSource.loadGames(dbPath);
  }

  @override
  Future<RustFsSettings> readSettings() {
    return _secureStorageDataSource.readSettings();
  }

  @override
  Future<void> saveSettings(RustFsSettings settings) {
    return _secureStorageDataSource.saveSettings(settings);
  }

  @override
  Future<TempLink> sendGame({
    required GameFile game,
    required RustFsSettings settings,
    required Duration validFor,
  }) async {
    final connection = RustFsConnection.fromUrl(
      rustfsUrl: settings.rustfsUrl,
      accessKey: settings.accessKey,
      secretKey: settings.secretKey,
    );

    final (link, objectName, expiresAt) = await _rustFsDataSource
        .uploadAndGetTempLink(
          connection: connection,
          filePath: game.path,
          validFor: validFor,
        );

    return TempLink(
      link: link,
      objectName: objectName,
      expiresAt: expiresAt,
      settings: settings,
    );
  }

  @override
  Future<void> deleteObject(TempLink link) {
    final connection = RustFsConnection.fromUrl(
      rustfsUrl: link.settings.rustfsUrl,
      accessKey: link.settings.accessKey,
      secretKey: link.settings.secretKey,
    );
    return _rustFsDataSource.deleteObject(
      connection: connection,
      objectName: link.objectName,
    );
  }
}
