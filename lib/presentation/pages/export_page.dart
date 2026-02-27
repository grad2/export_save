import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../domain/entities/game_file.dart';
import '../../domain/entities/rustfs_settings.dart';
import '../../domain/entities/temp_link.dart';
import '../bloc/export_bloc.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  final _formKey = GlobalKey<FormState>();
  String? _lastShownLink;

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Поле обязательно';
    }
    return null;
  }

  RustFsSettings _updateSettings(
    ExportBloc bloc,
    ExportViewModel state, {
    String? accessKey,
    String? secretKey,
    String? dbPath,
    String? rustfsUrl,
  }) {
    final updated = RustFsSettings(
      accessKey: accessKey ?? state.settings.accessKey,
      secretKey: secretKey ?? state.settings.secretKey,
      dbPath: dbPath ?? state.settings.dbPath,
      rustfsUrl: rustfsUrl ?? state.settings.rustfsUrl,
    );
    bloc.updateSettings(updated);
    return updated;
  }

  void _showLinksPopup(BuildContext context, List<TempLink> links) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Временные ссылки',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: links.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final entry = links[index];
                        final minutesLeft = entry.expiresAt
                            .difference(DateTime.now())
                            .inMinutes;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(entry.link),
                            const SizedBox(height: 8),
                            Center(
                              child: QrImageView(
                                data: entry.link,
                                version: QrVersions.auto,
                                size: 160,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('(осталось ~${minutesLeft < 0 ? 0 : minutesLeft} мин)'),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLatestLinkPopupIfNeeded(BuildContext context, ExportViewModel state) {
    if (state.tempLinks.isEmpty) {
      return;
    }

    final latest = state.tempLinks.last;
    if (_lastShownLink == latest.link) {
      return;
    }

    _lastShownLink = latest.link;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _showLinksPopup(context, [latest]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExportBloc>(
      builder: (context, bloc, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Выгрузка сейвов в RustFS'),
            actions: [
              StreamBuilder<ExportViewModel>(
                stream: bloc.stream,
                initialData: bloc.value,
                builder: (context, snapshot) {
                  final state = snapshot.data ?? ExportViewModel.initial();
                  if (state.tempLinks.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    tooltip: 'Активные ссылки',
                    onPressed: () => _showLinksPopup(context, state.tempLinks),
                    icon: const Icon(Icons.qr_code_2),
                  );
                },
              ),
            ],
          ),
          body: StreamBuilder<ExportViewModel>(
            stream: bloc.stream,
            initialData: bloc.value,
            builder: (context, snapshot) {
              final state = snapshot.data ?? ExportViewModel.initial();

              if (state.message != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message!)),
                  );
                  bloc.consumeMessage();
                });
              }

              _showLatestLinkPopupIfNeeded(context, state);

              return Padding(
                padding: const EdgeInsets.all(16),
                child: state.settings.isValid
                    ? _GamesScreen(
                        state: state,
                        onReload: () => bloc.loadGames(state.settings.dbPath),
                        onSendGame: (game) => bloc.sendGame(game),
                      )
                    : _SetupScreen(
                        formKey: _formKey,
                        state: state,
                        requiredValidator: _required,
                        onAccessKeyChanged: (value) => _updateSettings(
                          bloc,
                          state,
                          accessKey: value,
                        ),
                        onSecretKeyChanged: (value) => _updateSettings(
                          bloc,
                          state,
                          secretKey: value,
                        ),
                        onRustfsUrlChanged: (value) => _updateSettings(
                          bloc,
                          state,
                          rustfsUrl: value,
                        ),
                        onDbPathChanged: (value) => _updateSettings(
                          bloc,
                          state,
                          dbPath: value,
                        ),
                        onSave: () {
                          if (_formKey.currentState!.validate()) {
                            bloc.saveSettings(state.settings);
                          }
                        },
                      ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SetupScreen extends StatelessWidget {
  const _SetupScreen({
    required this.formKey,
    required this.state,
    required this.requiredValidator,
    required this.onAccessKeyChanged,
    required this.onSecretKeyChanged,
    required this.onRustfsUrlChanged,
    required this.onDbPathChanged,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final ExportViewModel state;
  final String? Function(String?) requiredValidator;
  final ValueChanged<String> onAccessKeyChanged;
  final ValueChanged<String> onSecretKeyChanged;
  final ValueChanged<String> onRustfsUrlChanged;
  final ValueChanged<String> onDbPathChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Экран 1/2: заполните параметры подключения',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: state.settings.accessKey,
            decoration: const InputDecoration(labelText: 'RustFS Access Key'),
            validator: requiredValidator,
            onChanged: onAccessKeyChanged,
          ),
          TextFormField(
            initialValue: state.settings.secretKey,
            decoration: const InputDecoration(labelText: 'RustFS Secret Key'),
            obscureText: true,
            validator: requiredValidator,
            onChanged: onSecretKeyChanged,
          ),
          TextFormField(
            initialValue: state.settings.rustfsUrl,
            decoration: const InputDecoration(
              labelText: 'Ссылка на RustFS (например https://host:9000/bucket)',
            ),
            validator: requiredValidator,
            onChanged: onRustfsUrlChanged,
          ),
          TextFormField(
            initialValue: state.settings.dbPath,
            decoration: const InputDecoration(labelText: 'Путь к DB файлам'),
            validator: requiredValidator,
            onChanged: onDbPathChanged,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: state.isSaving ? null : onSave,
              child: Text(state.isSaving ? 'Сохранение...' : 'Сохранить и перейти'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GamesScreen extends StatelessWidget {
  const _GamesScreen({
    required this.state,
    required this.onReload,
    required this.onSendGame,
  });

  final ExportViewModel state;
  final VoidCallback onReload;
  final ValueChanged<GameFile> onSendGame;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Экран 2/2: выберите игру для отправки',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: state.isLoadingGames ? null : onReload,
            icon: const Icon(Icons.refresh),
            label: Text(state.isLoadingGames ? 'Чтение...' : 'Загрузить игры из DB'),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: state.games.isEmpty
              ? const Center(
                  child: Text('Список игр пуст. Проверьте путь к DB и обновите список.'),
                )
              : ListView.builder(
                  itemCount: state.games.length,
                  itemBuilder: (context, index) {
                    final game = state.games[index];
                    return ListTile(
                      title: Text(game.name),
                      subtitle: Text(
                        game.path,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: state.isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file),
                      onTap: state.isSending ? null : () => onSendGame(game),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
