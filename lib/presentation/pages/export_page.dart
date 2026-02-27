import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/game_file.dart';
import '../../domain/entities/rustfs_settings.dart';
import '../bloc/export_bloc.dart';

class ExportPage extends StatelessWidget {
  ExportPage({super.key});

  final _formKey = GlobalKey<FormState>();

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

  void _sendGame(ExportBloc bloc, GameFile game) {
    bloc.sendGame(game);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExportBloc>(
      builder: (context, bloc, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Выгрузка сейвов в RustFS')),
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

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            initialValue: state.settings.accessKey,
                            decoration: const InputDecoration(
                              labelText: 'RustFS Access Key',
                            ),
                            validator: _required,
                            onChanged: (value) => _updateSettings(
                              bloc,
                              state,
                              accessKey: value,
                            ),
                          ),
                          TextFormField(
                            initialValue: state.settings.secretKey,
                            decoration: const InputDecoration(
                              labelText: 'RustFS Secret Key',
                            ),
                            obscureText: true,
                            validator: _required,
                            onChanged: (value) => _updateSettings(
                              bloc,
                              state,
                              secretKey: value,
                            ),
                          ),
                          TextFormField(
                            initialValue: state.settings.rustfsUrl,
                            decoration: const InputDecoration(
                              labelText:
                                  'Ссылка на RustFS (например https://host:9000/bucket)',
                            ),
                            validator: _required,
                            onChanged: (value) => _updateSettings(
                              bloc,
                              state,
                              rustfsUrl: value,
                            ),
                          ),
                          TextFormField(
                            initialValue: state.settings.dbPath,
                            decoration: const InputDecoration(
                              labelText: 'Путь к DB файлам',
                            ),
                            validator: _required,
                            onChanged: (value) => _updateSettings(
                              bloc,
                              state,
                              dbPath: value,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: state.isSaving
                                      ? null
                                      : () {
                                          if (_formKey.currentState!.validate()) {
                                            bloc.saveSettings(state.settings);
                                          }
                                        },
                                  child: Text(
                                    state.isSaving
                                        ? 'Сохранение...'
                                        : 'Сохранить параметры',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: state.isLoadingGames
                                      ? null
                                      : () {
                                          if (_formKey.currentState!.validate()) {
                                            bloc.loadGames(state.settings.dbPath);
                                          }
                                        },
                                  child: Text(
                                    state.isLoadingGames
                                        ? 'Чтение...'
                                        : 'Загрузить игры из DB',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: state.games.isEmpty
                          ? const Center(
                              child: Text(
                                'Список игр пуст. Укажите путь и загрузите DB.',
                              ),
                            )
                          : ListView.builder(
                              itemCount: state.games.length,
                              itemBuilder: (context, index) {
                                final game = state.games[index];
                                return Card(
                                  child: ListTile(
                                    title: Text(game.name),
                                    subtitle: Text(game.path),
                                    trailing: TextButton(
                                      onPressed: state.isSending
                                          ? null
                                          : () {
                                              if (_formKey.currentState!.validate()) {
                                                _sendGame(bloc, game);
                                              }
                                            },
                                      child: const Text('Отправить'),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    if (state.tempLinks.isNotEmpty) ...[
                      const Divider(),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Активные временные ссылки:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView(
                          children: state.tempLinks.map((entry) {
                            final minutesLeft =
                                entry.expiresAt.difference(DateTime.now()).inMinutes;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '${entry.link} (осталось ~${minutesLeft} мин)',
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
