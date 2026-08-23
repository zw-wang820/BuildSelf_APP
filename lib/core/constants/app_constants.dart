/// Buildself 应用常量定义
class AppConstants {
  AppConstants._();

  // 应用信息
  static const String appName = 'BuildSelf';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // 数据库
  static const String databaseName = 'buildself.db';
  static const int databaseVersion = 3;

  // 本地存储 Key
  static const String keyUserId = 'user_id';
  static const String keyLoginType = 'login_type';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyThemeMode = 'theme_mode';
  static const String keyAppLockEnabled = 'app_lock_enabled';
  static const String keyAppLockPin = 'app_lock_pin';
  static const String keyDbEncryptionKey = 'db_encryption_key';
  static const String keyLastBackupTime = 'last_backup_time';
  static const String keyLocale = 'app_locale';
  static const String keyAppTextScale = 'app_text_scale';

  // 分页
  static const int defaultPageSize = 20;

  // 图片限制
  static const int maxLifeImages = 9;
  static const int maxMurmurImages = 3;

  // 回收站自动清理天数
  static const int trashAutoPurgeDays = 30;

  // 备份提醒间隔天数
  static const int backupReminderDays = 30;
}
