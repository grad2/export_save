import '../entities/rustfs_settings.dart';
import '../repositories/save_export_repository.dart';

class ReadSettingsUseCase {
  const ReadSettingsUseCase(this._repository);

  final SaveExportRepository _repository;

  Future<RustFsSettings> call() => _repository.readSettings();
}
