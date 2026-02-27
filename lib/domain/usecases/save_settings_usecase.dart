import '../entities/rustfs_settings.dart';
import '../repositories/save_export_repository.dart';

class SaveSettingsUseCase {
  const SaveSettingsUseCase(this._repository);

  final SaveExportRepository _repository;

  Future<void> call(RustFsSettings settings) => _repository.saveSettings(settings);
}
