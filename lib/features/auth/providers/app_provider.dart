import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buildself/core/constants/app_constants.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/user_model.dart';
import 'package:buildself/data/repositories/auth_repository.dart';

/// 全局应用状态管理
///
/// 管理当前用户登录状态，使用 ChangeNotifier + SharedPreferences 持久化
class AppProvider extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();

  UserModel? _currentUser;
  bool _isLoggedIn = false;
  bool _initialized = false;
  // 默认深色主题
  ThemeMode _themeMode = ThemeMode.dark;
  // 默认简体中文
  AppLocale _appLocale = AppLocale.zhCN;

  // 默认标准字号缩放
  double _textScale = 1.0;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get initialized => _initialized;
  String get userId => _currentUser?.userId ?? '';
  ThemeMode get themeMode => _themeMode;
  AppLocale get appLocale => _appLocale;
  Locale get locale => _appLocale.locale;
  double get textScale => _textScale;

  /// 初始化 — 检查本地登录状态
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loggedIn = prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
      final userId = prefs.getString(AppConstants.keyUserId);

      // 读取主题模式
      final themeIndex = prefs.getInt(AppConstants.keyThemeMode);
      if (themeIndex != null && themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[themeIndex];
      }

      // 读取语言设置
      final localeIndex = prefs.getInt(AppConstants.keyLocale);
      if (localeIndex != null && localeIndex >= 0 && localeIndex < AppLocale.values.length) {
        _appLocale = AppLocale.values[localeIndex];
      }
      AppStrings.setLocale(_appLocale);

      // 读取字号缩放
      final textScale = prefs.getDouble(AppConstants.keyAppTextScale);
      if (textScale != null && textScale >= 0.8 && textScale <= 1.4) {
        _textScale = textScale;
      }

      if (loggedIn && userId != null) {
        final user = await _authRepo.getCurrentUser(userId);
        if (user != null) {
          _currentUser = user;
          _isLoggedIn = true;
        }
      }
    } catch (e) {
      debugPrint('AppProvider init error: $e');
    }
    _initialized = true;
    notifyListeners();
  }

  /// 切换主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyThemeMode, mode.index);
    notifyListeners();
  }

  /// 切换语言
  Future<void> setLocale(AppLocale appLocale) async {
    _appLocale = appLocale;
    AppStrings.setLocale(appLocale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyLocale, appLocale.index);
    notifyListeners();
  }

  /// 微信登录
  Future<void> loginWithWechat({
    required String openId,
    required String nickname,
    String? avatarPath,
  }) async {
    final user = await _authRepo.loginWithWechat(
      openId: openId,
      nickname: nickname,
      avatarPath: avatarPath,
    );
    await _saveLoginState(user);
  }

  /// 手机号登录
  Future<void> loginWithPhone(String phone) async {
    final user = await _authRepo.loginWithPhone(phone: phone);
    await _saveLoginState(user);
  }

  /// 保存登录状态
  Future<void> _saveLoginState(UserModel user) async {
    _currentUser = user;
    _isLoggedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsLoggedIn, true);
    await prefs.setString(AppConstants.keyUserId, user.userId);
    notifyListeners();
  }

  /// 更新用户信息
  Future<void> updateUser(UserModel user) async {
    await _authRepo.updateUser(user);
    _currentUser = user;
    notifyListeners();
  }

  /// 设置全局字号缩放
  Future<void> setTextScale(double value) async {
    _textScale = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.keyAppTextScale, value);
    notifyListeners();
  }

  /// 退出登录
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsLoggedIn, false);
    await prefs.remove(AppConstants.keyUserId);
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
