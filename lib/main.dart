import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'config/theme_notifier.dart';
import 'services/auth_service.dart';
import 'services/checkin_service.dart';
import '../services/checkin_api_service.dart';
import 'config/sidebar_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  

  

  final authService    = AuthService();
  await authService.restoreSession();

  final checkinService = CheckInService();
  if (authService.currentUser?.id != null) {
    final checkinApiService = CheckInApiService(authService);
    await checkinService.init(authService.currentUser!.id, checkinApiService);
  }

  final prefs        = await SharedPreferences.getInstance();
  final isLightTheme = prefs.getBool('isLightTheme') ?? true;

  runApp(AirSheroApp(
    authService:    authService,
    checkinService: checkinService,
    initialLightTheme: isLightTheme,
  ));
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };


}

class AirSheroApp extends StatefulWidget {
  final AuthService    authService;
  final CheckInService checkinService;
  final bool           initialLightTheme;

  const AirSheroApp({
    super.key,
    required this.authService,
    required this.checkinService,
    required this.initialLightTheme,
  });

  @override
  State<AirSheroApp> createState() => _AirSheroAppState();
}

class _AirSheroAppState extends State<AirSheroApp> {
  late bool _isLightTheme;

  @override
  void initState() {
    super.initState();
    _isLightTheme = widget.initialLightTheme;
  }

  void _toggleTheme() async {
    setState(() => _isLightTheme = !_isLightTheme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLightTheme', _isLightTheme);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.authService),
        ChangeNotifierProvider.value(value: widget.checkinService),
        ChangeNotifierProvider(create: (_) => SidebarNotifier()),
      ],
      child: ThemeNotifier(
        isLightTheme: _isLightTheme,
        toggleTheme:  _toggleTheme,
        child: MaterialApp.router(
          title:                     'AirShero',
          debugShowCheckedModeBanner: false,
          theme:                     AppTheme.lightTheme,
          darkTheme:                 AppTheme.darkTheme,
          themeMode:                 _isLightTheme ? ThemeMode.light : ThemeMode.dark,
          scrollBehavior:            AppScrollBehavior(),
          routerConfig:              AppRouter.router,
        ),
      ),
    );
  }
}







