
import 'package:export_save/domain/entities/game_file.dart';

abstract class GameFilesDataSource {

  Future<List<GameFile>> loadGames(String dbPath);
}
