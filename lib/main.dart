import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'config/theme_notifier.dart';

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
    return ThemeNotifier(
      isLightTheme: _isLightTheme,
      toggleTheme: _toggleTheme,
      child: MaterialApp.router(
        title: 'AirShero F',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _isLightTheme ? ThemeMode.light : ThemeMode.dark,
        routerConfig: AppRouter.router,
      ),
    );
  }
}