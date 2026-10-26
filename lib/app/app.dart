import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

class ToggleMeApp extends StatelessWidget {
  const ToggleMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toggle me',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const Scaffold(
        body: SafeArea(
          child: Center(
            child: Text(
              'Toggle me',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
