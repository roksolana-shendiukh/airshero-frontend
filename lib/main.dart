import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'config/theme_notifier.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: ThemeNotifier(
        isLightTheme: _isLightTheme,
        toggleTheme: _toggleTheme,
        child: MaterialApp.router(
          title: 'AirShero',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _isLightTheme ? ThemeMode.light : ThemeMode.dark,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}