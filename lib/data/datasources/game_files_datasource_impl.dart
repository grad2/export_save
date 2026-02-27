import 'dart:io';

import 'package:export_save/domain/entities/game_file.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'game_files_datasource.dart';

@Singleton(as: GameFilesDataSource)
class GameFilesDataSourceImpl extends GameFilesDataSource {
  GameFilesDataSourceImpl() {
    sqfliteFfiInit();
  }

  static const _userGameQuery = 'SELECT * FROM GAMES;';
  static const _gameMapperQuery = 'SELECT * FROM STEAM_SAVES_MAPPINGS;';
  static final DatabaseFactory _databaseFactory = databaseFactoryFfi;

  @override
  Future<List<GameFile>> loadGames(String dbPath) async {
    final dbFiles = await _resolveDbFiles(dbPath);
    if (dbFiles.isEmpty) {
      throw const FileSystemException('No database files found');
    }

    final gamesByPath = <String, GameFile>{};

    for (final dbFile in dbFiles) {
      final parsedGames = await _readGamesFromDb(dbFile);
      for (final game in parsedGames) {
        gamesByPath[game.path.toLowerCase()] = game;
      }
    }

    final games = gamesByPath.values.toList()..sort((a, b) => a.name.compareTo(b.name));
    return games;
  }

  Future<List<File>> _resolveDbFiles(String input) async {
    final dbFiles = <File>[];
    final unique = <String>{};

    final rawPaths = input
        .split(RegExp(r'[\n;]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);

    for (final rawPath in rawPaths) {
      final expanded = _expandEnvironmentVariables(
        rawPath.replaceAll('"', '').trim(),
      );

      final absolutePath = p.isAbsolute(expanded)
          ? expanded
          : p.normalize(p.join(Directory.current.path, expanded));

      final asFile = File(absolutePath);
      if (await asFile.exists()) {
        final key = asFile.path.toLowerCase();
        if (unique.add(key)) {
          dbFiles.add(asFile);
        }
        continue;
      }

      final asDirectory = Directory(absolutePath);
      if (!await asDirectory.exists()) {
        continue;
      }

      final preferredFiles = [
        File(p.join(asDirectory.path, 'UserGame.db')),
        File(p.join(asDirectory.path, 'GameMapper.db')),
      ];

      for (final dbFile in preferredFiles) {
        if (await dbFile.exists()) {
          final key = dbFile.path.toLowerCase();
          if (unique.add(key)) {
            dbFiles.add(dbFile);
          }
        }
      }
    }

    return dbFiles;
  }

  Future<List<GameFile>> _readGamesFromDb(File dbFile) async {
    final games = <GameFile>[];

    await _readQueryRows(
      dbPath: dbFile.path,
      query: _userGameQuery,
      sourceName: dbFile.uri.pathSegments.last,
      games: games,
    );
    await _readQueryRows(
      dbPath: dbFile.path,
      query: _gameMapperQuery,
      sourceName: dbFile.uri.pathSegments.last,
      games: games,
    );

    return games;
  }

  Future<void> _readQueryRows({
    required String dbPath,
    required String query,
    required String sourceName,
    required List<GameFile> games,
  }) async {
    Database? database;
    try {
      database = await _databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );
      final rows = await database.rawQuery(query);

      for (final row in rows) {
        final name = (row['STEAM_ID'] ?? row['NAME'] ?? '').toString().trim();
        final rawPath = (row['SAVES_PATH'] ?? '').toString().trim();
        if (rawPath.isEmpty || row['ENABLED'] == 0) {
          continue;
        }

        final expandedPath = _expandEnvironmentVariables(rawPath);
        final resolvedPath = p.isAbsolute(expandedPath)
            ? expandedPath
            : p.normalize(p.join(Directory.current.path, expandedPath));

        games.add(
          GameFile(
            name: name.isEmpty ? '-' : name,
            path: resolvedPath,
          ),
        );
      }
    } on DatabaseException {
      return;
    } finally {
      await database?.close();
    }
  }

  String _expandEnvironmentVariables(String path) {
    var expanded = path;
    final windowsMatches = RegExp(r'%([^%]+)%').allMatches(expanded).toList();
    for (final match in windowsMatches) {
      final key = match.group(1);
      if (key == null || key.isEmpty) {
        continue;
      }

      final value = Platform.environment[key] ?? '';
      expanded = expanded.replaceAll(match.group(0)!, value);
    }

    return expanded;
  }
}
