import 'package:get_it/get_it.dart';

import '../data/datasources/game_files_datasource.dart';
import '../data/datasources/rustfs_datasource.dart';
import '../data/datasources/secure_storage_datasource.dart';
import '../data/repositories/save_export_repository_impl.dart';
import '../domain/repositories/save_export_repository.dart';
import '../domain/usecases/delete_expired_link_usecase.dart';
import '../domain/usecases/load_games_usecase.dart';
import '../domain/usecases/read_settings_usecase.dart';
import '../domain/usecases/save_settings_usecase.dart';
import '../domain/usecases/send_game_usecase.dart';
import '../presentation/bloc/export_bloc.dart';

final GetIt getIt = GetIt.instance;

void configureDependencies() {
  if (getIt.isRegistered<ExportBloc>()) {
    return;
  }

  getIt.registerLazySingleton(() => const SecureStorageDataSource());
  getIt.registerLazySingleton(() => const GameFilesDataSource());
  getIt.registerLazySingleton(() => const RustFsDataSource());

  getIt.registerLazySingleton<SaveExportRepository>(
    () => SaveExportRepositoryImpl(
      secureStorageDataSource: getIt(),
      gameFilesDataSource: getIt(),
      rustFsDataSource: getIt(),
    ),
  );

  getIt.registerLazySingleton(() => ReadSettingsUseCase(getIt()));
  getIt.registerLazySingleton(() => SaveSettingsUseCase(getIt()));
  getIt.registerLazySingleton(() => LoadGamesUseCase(getIt()));
  getIt.registerLazySingleton(() => SendGameUseCase(getIt()));
  getIt.registerLazySingleton(() => DeleteExpiredLinkUseCase(getIt()));

  getIt.registerFactory(
    () => ExportBloc(
      readSettingsUseCase: getIt(),
      saveSettingsUseCase: getIt(),
      loadGamesUseCase: getIt(),
      sendGameUseCase: getIt(),
      deleteExpiredLinkUseCase: getIt(),
    ),
  );
}
