import '../../domain/entities/game_file.dart';
import '../../domain/entities/rustfs_settings.dart';
import '../../domain/entities/temp_link.dart';

class ExportState {
  const ExportState({
    required this.settings,
    required this.games,
    required this.tempLinks,
    required this.isSaving,
    required this.isLoadingGames,
    required this.isSending,
    required this.message,
  });

  factory ExportState.initial() => const ExportState(
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

  ExportState copyWith({
    RustFsSettings? settings,
    List<GameFile>? games,
    List<TempLink>? tempLinks,
    bool? isSaving,
    bool? isLoadingGames,
    bool? isSending,
    String? message,
    bool clearMessage = false,
  }) {
    return ExportState(
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
