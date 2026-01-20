import 'package:flutter/material.dart';
import 'theme.dart';

/// Main System App Widget
class SystemApp extends StatelessWidget {
  const SystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Manhwa System',
      theme: AppTheme.darkTheme,
      home: const Scaffold(
        body: Center(
          child: Text('System Home Page - Refactored Architecture Ready'),
        ),
      ),
    );
  }
}
