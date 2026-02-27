import 'dart:io';

import '../../domain/entities/game_file.dart';

class GameFilesDataSource {
  const GameFilesDataSource();

  Future<List<GameFile>> loadGames(String dbPath) async {
    final dir = Directory(dbPath);
    if (!await dir.exists()) {
      throw const FileSystemException('Directory does not exist');
    }

    final files = await dir
        .list(recursive: true)
        .where((entity) => entity is File)
        .cast<File>()
        .where(
          (file) =>
              file.path.endsWith('.db') ||
              file.path.endsWith('.sqlite') ||
              file.path.endsWith('.sav'),
        )
        .toList();

    final games = files
        .map(
          (file) => GameFile(
            name: file.uri.pathSegments.isNotEmpty
                ? file.uri.pathSegments.last
                : file.path,
            path: file.path,
          ),
        )
        .toList();

    games.sort((a, b) => a.name.compareTo(b.name));
    return games;
  }
}
