import 'package:flutter/material.dart';
import 'package:smart_composer_flutter/smart_composer_flutter.dart';

import 'shell.dart';

void main() {
  ReferenceRegistry.ensureDefaults();
  runApp(const ExampleApp());
}

/// Root of the example app. Holds the dark/light theme toggle and the tab shell,
/// reproducing the React showcase one-to-one.
class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  Brightness _brightness = Brightness.dark;

  void _toggleTheme() {
    setState(() {
      _brightness = _brightness == Brightness.dark ? Brightness.light : Brightness.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final composerTheme = _brightness == Brightness.dark ? ComposerTheme.dark() : ComposerTheme.light();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartComposer · GeniusLink',
      theme: ThemeData(
        useMaterial3: true,
        brightness: _brightness,
        scaffoldBackgroundColor: composerTheme.pageBg,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: composerTheme.accent,
          brightness: _brightness,
        ),
      ),
      home: ComposerThemeScope(
        theme: composerTheme,
        child: ShowcaseShell(
          brightness: _brightness,
          onToggleTheme: _toggleTheme,
        ),
      ),
    );
  }
}
