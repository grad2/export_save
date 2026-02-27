import 'package:flutter/material.dart';

import 'core/service_locator.dart';
import 'presentation/pages/export_page.dart';

void main() {
  configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Save Export',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: ExportPage(bloc: getIt()),
    );
  }
}
