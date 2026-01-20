import 'package:flutter/material.dart';
import 'theme.dart';
import '../ui/pages/system_home_page.dart';

/// Main System App Widget
class SystemApp extends StatelessWidget {
  const SystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Manhwa System',
      theme: AppTheme.darkTheme,
      home: const SystemHomePage(),
    );
  }
}
