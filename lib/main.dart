import 'package:export_save/di/di.dart';
import 'package:export_save/presentation/bloc/export_bloc.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'presentation/pages/export_page.dart';

void main() {
  configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(
          create: (_)=>getIt<ExportBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'Save Export',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
        home: ExportPage(),
      ),
    );
  }
}
