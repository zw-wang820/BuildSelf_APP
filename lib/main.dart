import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/app_constants.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/theme/app_theme.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/core/router/app_router.dart';
import 'package:buildself/data/database/database_provider.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/shared/layouts/main_scaffold.dart';
import 'package:buildself/features/auth/screens/welcome_screen.dart';

/// Buildself — 个人成长记录 APP
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 极简风：状态栏透明
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF1A1A1C),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const BuildselfApp());
}

class BuildselfApp extends StatefulWidget {
  const BuildselfApp({Key? key}) : super(key: key);

  @override
  State<BuildselfApp> createState() => _BuildselfAppState();
}

class _BuildselfAppState extends State<BuildselfApp> {
  final AppProvider _appProvider = AppProvider();

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      await DatabaseProvider.instance.database;
      await DatabaseProvider.instance.purgeExpiredTrash();
      await _appProvider.init();
    } catch (e) {
      debugPrint('Init error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _appProvider,
      child: Consumer<AppProvider>(
        builder: (context, provider, _) {
          Widget home;
          if (!provider.initialized) {
            home = const Scaffold(body: Center(child: CircularProgressIndicator()));
          } else {
            home = provider.isLoggedIn ? const MainScaffold() : const WelcomeScreen();
          }
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: provider.themeMode,
            home: home,
            onGenerateRoute: AppRouter.onGenerateRoute,
            color: AppColors.primary,
            locale: provider.locale,
            supportedLocales: const [
              Locale('zh', 'CN'),
              Locale('zh', 'TW'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: provider.textScale),
              child: child!,
            ),
          );
        },
      ),
    );
  }
}
