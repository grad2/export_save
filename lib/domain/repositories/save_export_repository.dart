import '../entities/game_file.dart';
import '../entities/rustfs_settings.dart';
import '../entities/temp_link.dart';


abstract class SaveExportRepository {
  Future<RustFsSettings> readSettings();
  Future<void> saveSettings(RustFsSettings settings);
  Future<List<GameFile>> loadGames(String dbPath);
  Future<TempLink> sendGame({
    required GameFile game,
    required RustFsSettings settings,
    required Duration validFor,
  });
  Future<void> deleteObject(TempLink link);
}
