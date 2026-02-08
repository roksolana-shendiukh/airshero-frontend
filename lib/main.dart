import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const AirSheroApp());
}

class AirSheroApp extends StatefulWidget {
  const AirSheroApp({super.key});

  @override
  State<AirSheroApp> createState() => _AirSheroAppState();
}

class _AirSheroAppState extends State<AirSheroApp> {
  bool _isLightTheme = true;

  void _toggleTheme() {
    setState(() {
      _isLightTheme = !_isLightTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AirShero F',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isLightTheme ? ThemeMode.light : ThemeMode.dark,
      home: HomePage(
        isLightTheme: _isLightTheme,
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}