// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../data/datasources/game_files_datasource.dart' as _i612;
import '../data/datasources/rustfs_datasource.dart' as _i221;
import '../data/datasources/secure_storage_datasource.dart' as _i656;
import '../domain/repositories/save_export_repository_impl.dart' as _i544;
import '../domain/repositories/save_export_repository.dart' as _i264;
import '../domain/usecases/delete_expired_link_usecase.dart' as _i802;
import '../domain/usecases/load_games_usecase.dart' as _i512;
import '../domain/usecases/read_settings_usecase.dart' as _i77;
import '../domain/usecases/save_settings_usecase.dart' as _i848;
import '../domain/usecases/send_game_usecase.dart' as _i916;
import '../presentation/bloc/export_bloc.dart' as _i813;

// initializes the registration of main-scope dependencies inside of GetIt
_i174.GetIt $initGetIt(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) {
  final gh = _i526.GetItHelper(getIt, environment, environmentFilter);
  gh.singleton<_i264.SaveExportRepository>(
    () => _i544.SaveExportRepositoryImpl(
      secureStorageDataSource: gh<_i656.SecureStorageDataSource>(),
      gameFilesDataSource: gh<_i612.GameFilesDataSource>(),
      rustFsDataSource: gh<_i221.RustFsDataSource>(),
    ),
  );
  gh.factory<_i813.ExportBloc>(
    () => _i813.ExportBloc(
      readSettingsUseCase: gh<_i77.ReadSettingsUseCase>(),
      saveSettingsUseCase: gh<_i848.SaveSettingsUseCase>(),
      loadGamesUseCase: gh<_i512.LoadGamesUseCase>(),
      sendGameUseCase: gh<_i916.SendGameUseCase>(),
      deleteExpiredLinkUseCase: gh<_i802.DeleteExpiredLinkUseCase>(),
    ),
  );
  return getIt;
}
