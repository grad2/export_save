import 'dart:io';

import 'package:export_save/domain/entities/game_file.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;

import 'game_files_datasource.dart';

@Singleton(as: GameFilesDataSource)
class GameFilesDataSourceImpl extends GameFilesDataSource {
  static const _userGameQuery = 'SELECT NAME, SAVES_PATH FROM GAMES;';
  static const _gameMapperQuery =
      'SELECT SAVES_PATH FROM STEAM_SAVES_MAPPINGS;';

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
    final result = await Process.run('sqlite3', [dbPath, '-separator', '|', query]);
    if (result.exitCode != 0) {
      return;
    }

    final output = (result.stdout ?? '').toString();
    if (output.trim().isEmpty) {
      return;
    }

    for (final line in output.split('\n')) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) {
        continue;
      }

      final split = trimmedLine.split('|');
      final name = split.length >= 2 ? split.first.trim() : '';
      final rawPath = split.length >= 2 ? split[1].trim() : split.first.trim();
      if (rawPath.isEmpty) {
        continue;
      }

      final expandedPath = _expandEnvironmentVariables(rawPath);
      final resolvedPath = p.isAbsolute(expandedPath)
          ? expandedPath
          : p.normalize(p.join(Directory.current.path, expandedPath));

      games.add(
        GameFile(
          name: name.isEmpty ? '$sourceName: Unknown' : name,
          path: resolvedPath,
        ),
      );
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
