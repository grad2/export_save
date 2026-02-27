import 'package:injectable/injectable.dart';

import '../entities/game_file.dart';
import '../repositories/save_export_repository.dart';

@singleton
class LoadGamesUseCase {
  const LoadGamesUseCase(this._repository);

  final SaveExportRepository _repository;

  Future<List<GameFile>> call(String dbPath) => _repository.loadGames(dbPath);
}
