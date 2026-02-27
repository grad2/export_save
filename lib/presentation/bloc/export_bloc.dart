import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

import '../../domain/entities/game_file.dart';
import '../../domain/entities/rustfs_settings.dart';
import '../../domain/entities/temp_link.dart';
import '../../domain/usecases/delete_expired_link_usecase.dart';
import '../../domain/usecases/load_games_usecase.dart';
import '../../domain/usecases/read_settings_usecase.dart';
import '../../domain/usecases/save_settings_usecase.dart';
import '../../domain/usecases/send_game_usecase.dart';

class ExportViewModel {
  const ExportViewModel({
    required this.settings,
    required this.games,
    required this.tempLinks,
    required this.isSaving,
    required this.isLoadingGames,
    required this.isSending,
    required this.message,
  });

  factory ExportViewModel.initial() => const ExportViewModel(
    settings: RustFsSettings(
      accessKey: '',
      secretKey: '',
      dbPath: '',
      rustfsUrl: '',
    ),
    games: [],
    tempLinks: [],
    isSaving: false,
    isLoadingGames: false,
    isSending: false,
    message: null,
  );

  final RustFsSettings settings;
  final List<GameFile> games;
  final List<TempLink> tempLinks;
  final bool isSaving;
  final bool isLoadingGames;
  final bool isSending;
  final String? message;

  ExportViewModel copyWith({
    RustFsSettings? settings,
    List<GameFile>? games,
    List<TempLink>? tempLinks,
    bool? isSaving,
    bool? isLoadingGames,
    bool? isSending,
    String? message,
    bool clearMessage = false,
  }) {
    return ExportViewModel(
      settings: settings ?? this.settings,
      games: games ?? this.games,
      tempLinks: tempLinks ?? this.tempLinks,
      isSaving: isSaving ?? this.isSaving,
      isLoadingGames: isLoadingGames ?? this.isLoadingGames,
      isSending: isSending ?? this.isSending,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

@injectable
class ExportBloc {
  ExportBloc({
    required ReadSettingsUseCase readSettingsUseCase,
    required SaveSettingsUseCase saveSettingsUseCase,
    required LoadGamesUseCase loadGamesUseCase,
    required SendGameUseCase sendGameUseCase,
    required DeleteExpiredLinkUseCase deleteExpiredLinkUseCase,
  }) : _readSettingsUseCase = readSettingsUseCase,
       _saveSettingsUseCase = saveSettingsUseCase,
       _loadGamesUseCase = loadGamesUseCase,
       _sendGameUseCase = sendGameUseCase,
       _deleteExpiredLinkUseCase = deleteExpiredLinkUseCase {
    init();
  }

  final ReadSettingsUseCase _readSettingsUseCase;
  final SaveSettingsUseCase _saveSettingsUseCase;
  final LoadGamesUseCase _loadGamesUseCase;
  final SendGameUseCase _sendGameUseCase;
  final DeleteExpiredLinkUseCase _deleteExpiredLinkUseCase;

  final BehaviorSubject<ExportViewModel> _state = BehaviorSubject.seeded(
    ExportViewModel.initial(),
  );

  Stream<ExportViewModel> get stream => _state.stream;
  ExportViewModel get value => _state.value;

  Timer? _cleanupTimer;

  Future<void> init() async {
    final settings = await _readSettingsUseCase();
    _emit(value.copyWith(settings: settings, clearMessage: true));
    if (settings.dbPath.trim().isNotEmpty) {
      await loadGames(settings.dbPath);
    }

    _cleanupTimer ??= Timer.periodic(
      const Duration(minutes: 1),
      (_) => cleanupExpiredLinks(),
    );
  }

  void updateSettings(RustFsSettings settings) {
    _emit(value.copyWith(settings: settings, clearMessage: true));
  }

  Future<void> saveSettings(RustFsSettings settings) async {
    if (!settings.isValid) {
      _emit(value.copyWith(message: 'Заполните все поля'));
      return;
    }

    _emit(value.copyWith(isSaving: true, message: null));
    await _saveSettingsUseCase(settings);
    _emit(
      value.copyWith(
        settings: settings,
        isSaving: false,
        message: 'Параметры сохранены в secure storage',
      ),
    );
  }

  Future<void> loadGames(String dbPath) async {
    _emit(value.copyWith(isLoadingGames: true, clearMessage: true));
    try {
      final games = await _loadGamesUseCase(dbPath);
      _emit(value.copyWith(games: games, isLoadingGames: false));
    } catch (_) {
      _emit(
        value.copyWith(
          isLoadingGames: false,
          message: 'Не удалось прочитать DB файлы',
        ),
      );
    }
  }

  Future<void> sendGame(GameFile game) async {
    final settings = value.settings;
    if (!settings.isValid) {
      _emit(value.copyWith(message: 'Заполните все поля'));
      return;
    }

    _emit(value.copyWith(isSending: true, clearMessage: true));

    try {
      final tempLink = await _sendGameUseCase(game: game, settings: settings);
      final links = [...value.tempLinks, tempLink];
      _emit(
        value.copyWith(
          tempLinks: links,
          isSending: false,
          message: 'Файл отправлен в RustFS, ссылка на 1 час',
        ),
      );
    } catch (_) {
      _emit(
        value.copyWith(
          isSending: false,
          message: 'Ошибка отправки в RustFS через MinIO',
        ),
      );
    }
  }

  Future<void> cleanupExpiredLinks() async {
    final now = DateTime.now();
    final expired = value.tempLinks.where((e) => now.isAfter(e.expiresAt)).toList();
    if (expired.isEmpty) {
      return;
    }

    for (final link in expired) {
      try {
        await _deleteExpiredLinkUseCase(link);
      } catch (_) {}
    }

    final active = value.tempLinks.where((e) => now.isBefore(e.expiresAt)).toList();
    _emit(value.copyWith(tempLinks: active));
  }

  void consumeMessage() {
    if (value.message != null) {
      _emit(value.copyWith(clearMessage: true));
    }
  }

  void _emit(ExportViewModel state) {
    if (!_state.isClosed) {
      _state.add(state);
    }
  }

  Future<void> dispose() async {
    _cleanupTimer?.cancel();
    await _state.close();
  }
}
