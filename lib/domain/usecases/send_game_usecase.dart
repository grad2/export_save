import 'package:injectable/injectable.dart';

import '../entities/game_file.dart';
import '../entities/rustfs_settings.dart';
import '../entities/temp_link.dart';
import '../repositories/save_export_repository.dart';

@singleton
class SendGameUseCase {
  const SendGameUseCase(this._repository);

  final SaveExportRepository _repository;

  Future<TempLink> call({
    required GameFile game,
    required RustFsSettings settings,
    Duration validFor = const Duration(hours: 1),
  }) {
    return _repository.sendGame(
      game: game,
      settings: settings,
      validFor: validFor,
    );
  }
}
