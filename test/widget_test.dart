import 'package:export_save/domain/entities/game_file.dart';
import 'package:export_save/domain/entities/rustfs_settings.dart';
import 'package:export_save/domain/entities/temp_link.dart';
import 'package:export_save/domain/repositories/save_export_repository.dart';
import 'package:export_save/domain/usecases/delete_expired_link_usecase.dart';
import 'package:export_save/domain/usecases/load_games_usecase.dart';
import 'package:export_save/domain/usecases/read_settings_usecase.dart';
import 'package:export_save/domain/usecases/save_settings_usecase.dart';
import 'package:export_save/domain/usecases/send_game_usecase.dart';
import 'package:export_save/presentation/bloc/export_bloc.dart';
import 'package:export_save/presentation/pages/export_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSaveExportRepository implements SaveExportRepository {
  const FakeSaveExportRepository();

  @override
  Future<void> deleteObject(TempLink link) async {}

  @override
  Future<List<GameFile>> loadGames(String dbPath) async {
    return const [GameFile(name: 'eldenring.db', path: '/games/eldenring.db')];
  }

  @override
  Future<RustFsSettings> readSettings() async {
    return const RustFsSettings(
      accessKey: 'access',
      secretKey: 'secret',
      dbPath: '/games',
      rustfsUrl: 'https://rustfs.example.com/saves',
    );
  }

  @override
  Future<void> saveSettings(RustFsSettings settings) async {}

  @override
  Future<TempLink> sendGame({
    required GameFile game,
    required RustFsSettings settings,
    required Duration validFor,
  }) async {
    return TempLink(
      link: 'https://temp.link',
      objectName: 'exports/eldenring.db',
      expiresAt: DateTime.now().add(validFor),
      settings: settings,
    );
  }
}

void main() {
  testWidgets('renders export form and game list from stored path', (
    WidgetTester tester,
  ) async {
    const repository = FakeSaveExportRepository();
    final bloc = ExportBloc(
      readSettingsUseCase: ReadSettingsUseCase(repository),
      saveSettingsUseCase: SaveSettingsUseCase(repository),
      loadGamesUseCase: LoadGamesUseCase(repository),
      sendGameUseCase: SendGameUseCase(repository),
      deleteExpiredLinkUseCase: DeleteExpiredLinkUseCase(repository),
    );

    await tester.pumpWidget(
      MaterialApp(home: ExportPage(bloc: bloc)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Выгрузка сейвов в RustFS'), findsOneWidget);
    expect(find.text('Сохранить параметры'), findsOneWidget);
    expect(find.text('eldenring.db'), findsOneWidget);
    expect(find.text('Отправить'), findsOneWidget);
  });
}
