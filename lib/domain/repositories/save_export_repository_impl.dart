import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;

import '../entities/game_file.dart';
import '../entities/rustfs_settings.dart';
import '../exceptions/file_size_limit_exceeded_exception.dart';
import '../entities/temp_link.dart';
import 'save_export_repository.dart';
import '../../data/datasources/game_files_datasource.dart';
import '../../data/datasources/rustfs_datasource.dart';
import '../../data/datasources/secure_storage_datasource.dart';
import '../../data/models/rustfs_connection.dart';

@Singleton(as: SaveExportRepository)
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

  static const int _maxUploadSizeBytes = 3 * 1024 * 1024 * 1024;

  @override
  Future<TempLink> sendGame({
    required GameFile game,
    required RustFsSettings settings,
    required Duration validFor,
  }) async {
    final file = File(game.path);
    Directory? tempDirectory;
    var fileToUploadPath = game.path;

    try {
      tempDirectory = await Directory.systemTemp.createTemp('export_save_');
      fileToUploadPath = await _archiveSave(
        sourceFile: file,
        tempDirectory: tempDirectory,
      );

      final fileSize = await File(fileToUploadPath).length();

      if (fileSize > _maxUploadSizeBytes) {
        throw FileSizeLimitExceededException(
          maxBytes: _maxUploadSizeBytes,
          actualBytes: fileSize,
        );
      }

      final connection = RustFsConnection.fromUrl(
        rustfsUrl: settings.rustfsUrl,
        accessKey: settings.accessKey,
        secretKey: settings.secretKey,
      );

      final (link, objectName, expiresAt) = await _rustFsDataSource
          .uploadAndGetTempLink(
            connection: connection,
            filePath: fileToUploadPath,
            validFor: validFor,
          );

      return TempLink(
        link: link,
        objectName: objectName,
        expiresAt: expiresAt,
        settings: settings,
      );
    } finally {
      if (tempDirectory != null && await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    }
  }

  Future<String> _archiveSave({
    required File sourceFile,
    required Directory tempDirectory,
  }) async {

    final sourcePath = sourceFile.path;
    final sourceType = await FileSystemEntity.type(sourcePath);

    if (sourceType == FileSystemEntityType.notFound) {
      throw FileSystemException('Save path was not found', sourcePath);
    }

    final sourceName = p.basename(sourcePath);
    final archivePath = p.join(tempDirectory.path, '$sourceName.zip');

    final encoder = ZipFileEncoder();
    encoder.create(archivePath);

    if (sourceType == FileSystemEntityType.file) {
      encoder.addFile(File(sourcePath), sourceName);
    } else if (sourceType == FileSystemEntityType.directory) {
      final sourceDirectory = Directory(sourcePath);
      final files = await sourceDirectory
          .list(recursive: true, followLinks: false)
          .where((entity) => entity is File)
          .cast<File>()
          .toList();

      for (final file in files) {
        final relativePath = p.relative(file.path, from: sourceDirectory.path);
        final archiveEntryPath = p.join(sourceName, relativePath).replaceAll('\\', '/');
        encoder.addFile(file, archiveEntryPath);
      }
    }


    encoder.close();

    return archivePath;
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
