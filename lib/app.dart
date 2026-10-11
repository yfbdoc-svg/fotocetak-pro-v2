import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/workspace_screen.dart';

class FotoCetakApp extends StatelessWidget {
  const FotoCetakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FotoCetak Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const WorkspaceScreen(),
    );
  }
}
