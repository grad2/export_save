import '../entities/temp_link.dart';
import '../repositories/save_export_repository.dart';

class DeleteExpiredLinkUseCase {
  const DeleteExpiredLinkUseCase(this._repository);

  final SaveExportRepository _repository;

  Future<void> call(TempLink link) => _repository.deleteObject(link);
}
