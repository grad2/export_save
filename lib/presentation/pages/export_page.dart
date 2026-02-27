import 'package:flutter/material.dart';

import '../../domain/entities/rustfs_settings.dart';
import '../bloc/export_bloc.dart';
import '../bloc/export_state.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({required this.bloc, super.key});

  final ExportBloc bloc;

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  final _formKey = GlobalKey<FormState>();
  final _accessController = TextEditingController();
  final _secretController = TextEditingController();
  final _dbPathController = TextEditingController();
  final _rustfsUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.bloc.init();
  }

  @override
  void dispose() {
    _accessController.dispose();
    _secretController.dispose();
    _dbPathController.dispose();
    _rustfsUrlController.dispose();
    widget.bloc.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Поле обязательно';
    }
    return null;
  }

  RustFsSettings _settingsFromFields() {
    return RustFsSettings(
      accessKey: _accessController.text,
      secretKey: _secretController.text,
      dbPath: _dbPathController.text,
      rustfsUrl: _rustfsUrlController.text,
    );
  }

  void _syncControllers(ExportState state) {
    if (_accessController.text.isEmpty && state.settings.accessKey.isNotEmpty) {
      _accessController.text = state.settings.accessKey;
    }
    if (_secretController.text.isEmpty && state.settings.secretKey.isNotEmpty) {
      _secretController.text = state.settings.secretKey;
    }
    if (_dbPathController.text.isEmpty && state.settings.dbPath.isNotEmpty) {
      _dbPathController.text = state.settings.dbPath;
    }
    if (_rustfsUrlController.text.isEmpty && state.settings.rustfsUrl.isNotEmpty) {
      _rustfsUrlController.text = state.settings.rustfsUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Выгрузка сейвов в RustFS')),
      body: StreamBuilder<ExportState>(
        stream: widget.bloc.stream,
        initialData: widget.bloc.value,
        builder: (context, snapshot) {
          final state = snapshot.data ?? ExportState.initial();
          _syncControllers(state);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || state.message == null) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
            widget.bloc.consumeMessage();
          });

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _accessController,
                        decoration: const InputDecoration(
                          labelText: 'RustFS Access Key',
                        ),
                        validator: _required,
                      ),
                      TextFormField(
                        controller: _secretController,
                        decoration: const InputDecoration(
                          labelText: 'RustFS Secret Key',
                        ),
                        obscureText: true,
                        validator: _required,
                      ),
                      TextFormField(
                        controller: _rustfsUrlController,
                        decoration: const InputDecoration(
                          labelText:
                              'Ссылка на RustFS (например https://host:9000/bucket)',
                        ),
                        validator: _required,
                      ),
                      TextFormField(
                        controller: _dbPathController,
                        decoration: const InputDecoration(
                          labelText: 'Путь к DB файлам',
                        ),
                        validator: _required,
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
                                        final settings = _settingsFromFields();
                                        widget.bloc.updateSettings(settings);
                                        widget.bloc.saveSettings(settings);
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
                                        final settings = _settingsFromFields();
                                        widget.bloc.updateSettings(settings);
                                        widget.bloc.loadGames(settings.dbPath);
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
                                            widget.bloc.updateSettings(
                                              _settingsFromFields(),
                                            );
                                            widget.bloc.sendGame(game);
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
  }
}
