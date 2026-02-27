import 'package:injectable/injectable.dart';

import '../entities/rustfs_settings.dart';
import '../repositories/save_export_repository.dart';

@singleton
class SaveSettingsUseCase {
  const SaveSettingsUseCase(this._repository);

  final SaveExportRepository _repository;

  Future<void> call(RustFsSettings settings) => _repository.saveSettings(settings);
}
