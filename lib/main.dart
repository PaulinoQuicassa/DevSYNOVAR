import 'package:flutter/material.dart';
import 'app_stores.dart';
import 'screens/root_shell.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await hydrateAllStores();
  runApp(const FilaCertaApp());
}

class FilaCertaApp extends StatelessWidget {
  const FilaCertaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fila Certa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const RootShell(),
    );
  }
}
