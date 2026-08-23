import 'dart:ui' show Locale;

/// 支持的语言
enum AppLocale {
  zhCN('简体中文', Locale('zh', 'CN')),
  zhTW('繁體中文', Locale('zh', 'TW')),
  enUS('English', Locale('en', 'US'));

  const AppLocale(this.displayName, this.locale);
  final String displayName;
  final Locale locale;

  /// 从 Locale 反查 AppLocale
  static AppLocale fromLocale(Locale? locale) {
    if (locale == null) return AppLocale.zhCN;
    for (final e in AppLocale.values) {
      if (e.locale.languageCode == locale.languageCode &&
          e.locale.countryCode == locale.countryCode) {
        return e;
      }
    }
    return AppLocale.zhCN;
  }
}

/// Buildself 字符串常量 — 支持 zhCN / zhTW / enUS 三种语言
class AppStrings {
  AppStrings._();

  static AppLocale _locale = AppLocale.zhCN;

  /// 由 AppProvider 在初始化和切换语言时调用
  static void setLocale(AppLocale locale) {
    _locale = locale;
  }

  static AppLocale get currentLocale => _locale;

  static String _t(String key) {
    return _data[_locale]?[key] ?? _data[AppLocale.zhCN]![key] ?? key;
  }

  // ============ 应用通用 ============
  static String get appName => _t('appName');
  static String get appSlogan => _t('appSlogan');
  static String get appSloganFull => _t('appSloganFull');

  // ============ 登录 ============
  static String get welcome => _t('welcome');
  static String get loginWechat => _t('loginWechat');
  static String get loginPhone => _t('loginPhone');
  static String get phoneInputHint => _t('phoneInputHint');
  static String get codeInputHint => _t('codeInputHint');
  static String get getCode => _t('getCode');
  static String get login => _t('login');
  static String get privacyPolicyTip => _t('privacyPolicyTip');

  // ============ 底部导航 ============
  static String get tabHome => _t('tabHome');
  static String get tabWork => _t('tabWork');
  static String get tabLife => _t('tabLife');
  static String get tabGoal => _t('tabGoal');
  static String get tabReading => _t('tabReading');
  static String get tabMine => _t('tabMine');

  // ============ 首页 ============
  static String get goodAfternoon => _t('goodAfternoon');
  static String get goodMorning => _t('goodMorning');
  static String get goodEvening => _t('goodEvening');
  static String get todayIs => _t('todayIs');
  static String get quickRecord => _t('quickRecord');
  static String get activeGoals => _t('activeGoals');
  static String get recentChanges => _t('recentChanges');
  static String get todayInHistory => _t('todayInHistory');
  static String get explorer => _t('explorer');
  static String get allItems => _t('allItems');
  static String get noActiveGoals => _t('noActiveGoals');
  static String get noReadingChanges => _t('noReadingChanges');
  static String get noHistoryRecords => _t('noHistoryRecords');

  // ============ 工作模块 ============
  static String get workTitle => _t('workTitle');
  static String get workExperience => _t('workExperience');
  static String get workInsight => _t('workInsight');
  static String get workReflection => _t('workReflection');
  static String get newWorkRecord => _t('newWorkRecord');

  // ============ 生活模块 ============
  static String get lifeTitle => _t('lifeTitle');
  static String get lifeBeauty => _t('lifeBeauty');
  static String get lifeInsight => _t('lifeInsight');
  static String get lifeReflection => _t('lifeReflection');
  static String get newLifeRecord => _t('newLifeRecord');

  // ============ 目标模块 ============
  static String get goalTitle => _t('goalTitle');
  static String get shortTermGoal => _t('shortTermGoal');
  static String get midTermGoal => _t('midTermGoal');
  static String get longTermGoal => _t('longTermGoal');
  static String get newGoal => _t('newGoal');
  static String get achievementWall => _t('achievementWall');
  static String get updateProgress => _t('updateProgress');
  static String get rewardLabel => _t('rewardLabel');
  static String get goalLog => _t('goalLog');

  // ============ 阅读模块 ============
  static String get readingTitle => _t('readingTitle');
  static String get bookshelf => _t('bookshelf');
  static String get addBook => _t('addBook');
  static String get noteExcerpt => _t('noteExcerpt');
  static String get noteInsight => _t('noteInsight');
  static String get noteThought => _t('noteThought');
  static String get noteChange => _t('noteChange');
  static String get newReadingNote => _t('newReadingNote');

  // ============ 碎碎念模块 ============
  static String get murmurTitle => _t('murmurTitle');
  static String get murmurHint => _t('murmurHint');
  static String get murmurSave => _t('murmurSave');

  // ============ 设置 ============
  static String get settings => _t('settings');
  static String get backupRestore => _t('backupRestore');
  static String get dataExport => _t('dataExport');
  static String get themeSetting => _t('themeSetting');
  static String get appLock => _t('appLock');
  static String get about => _t('about');
  static String get languageSetting => _t('languageSetting');
  static String get languageSubtitle => _t('languageSubtitle');
  static String get dataManagement => _t('dataManagement');
  static String get securityPrivacy => _t('securityPrivacy');
  static String get appearance => _t('appearance');
  static String get aboutSection => _t('aboutSection');
  static String get lastBackupNever => _t('lastBackupNever');
  static String get exportAsMarkdown => _t('exportAsMarkdown');
  static String get appLockSubtitle => _t('appLockSubtitle');
  static String get wechatLoginLabel => _t('wechatLoginLabel');
  static String get phoneLoginLabel => _t('phoneLoginLabel');
  static String get unbound => _t('unbound');
  static String get userIdLabel => _t('userIdLabel');
  static String get phoneNumberLabel => _t('phoneNumberLabel');
  static String get registerTimeLabel => _t('registerTimeLabel');
  static String get lastLoginLabel => _t('lastLoginLabel');
  static String get exportingData => _t('exportingData');
  static String get exportSuccess => _t('exportSuccess');
  static String get exportFailed => _t('exportFailed');
  static String get logout => _t('logout');
  static String get logoutButton => _t('logoutButton');
  static String get logoutConfirmMsg => _t('logoutConfirmMsg');

  // ============ 主题设置 ============
  static String get themeSystem => _t('themeSystem');
  static String get themeLight => _t('themeLight');
  static String get themeDark => _t('themeDark');
  static String get themeSystemSubtitle => _t('themeSystemSubtitle');
  static String get themeLightSubtitle => _t('themeLightSubtitle');
  static String get themeDarkSubtitle => _t('themeDarkSubtitle');

  // ============ 通用 ============
  static String get save => _t('save');
  static String get cancel => _t('cancel');
  static String get delete => _t('delete');
  static String get edit => _t('edit');
  static String get confirm => _t('confirm');
  static String get search => _t('search');
  static String get searchHint => _t('searchHint');
  static String get noData => _t('noData');
  static String get saveSuccess => _t('saveSuccess');
  static String get deleteSuccess => _t('deleteSuccess');
  static String get restore => _t('restore');
  static String get trash => _t('trash');
  static String get tags => _t('tags');
  static String get mood => _t('mood');
  static String get weather => _t('weather');
  static String get location => _t('location');
  static String get title => _t('title');
  static String get content => _t('content');
  static String get titleOptional => _t('titleOptional');
  static String get pageNotFound => _t('pageNotFound');

  // ============ 翻译数据 ============
  static final Map<AppLocale, Map<String, String>> _data = {
    // ================================================================
    // 简体中文
    // ================================================================
    AppLocale.zhCN: {
      'appName': 'Buildself',
      'appSlogan': '像建设新中国一样建设自己',
      'appSloganFull': '像建设新中国一样建设自己 — 每一次记录都是一块基石。',
      'welcome': '欢迎',
      'loginWechat': '微信登录',
      'loginPhone': '手机号登录',
      'phoneInputHint': '请输入手机号',
      'codeInputHint': '请输入验证码',
      'getCode': '获取验证码',
      'login': '登录',
      'privacyPolicyTip': '登录即代表同意《隐私政策》和《用户协议》',
      'tabHome': '首页',
      'tabWork': '工作',
      'tabLife': '生活',
      'tabGoal': '目标',
      'tabReading': '阅读',
      'tabMine': '我的',
      'goodAfternoon': '下午好',
      'goodMorning': '早上好',
      'goodEvening': '晚上好',
      'todayIs': '今天是',
      'quickRecord': '快捷记录',
      'activeGoals': '进行中的目标',
      'recentChanges': '近期改变',
      'todayInHistory': '往日今日',
      'explorer': '探索者',
      'allItems': '全部',
      'noActiveGoals': '暂无进行中的目标',
      'noReadingChanges': '暂无阅读改变记录',
      'noHistoryRecords': '暂无历史记录',
      'workTitle': '工作',
      'workExperience': '经验',
      'workInsight': '心得',
      'workReflection': '反思',
      'newWorkRecord': '新建工作记录',
      'lifeTitle': '生活',
      'lifeBeauty': '美好',
      'lifeInsight': '感悟',
      'lifeReflection': '反思',
      'newLifeRecord': '新建生活记录',
      'goalTitle': '目标管理',
      'shortTermGoal': '短期目标',
      'midTermGoal': '中期目标',
      'longTermGoal': '长期目标',
      'newGoal': '新建目标',
      'achievementWall': '成就墙',
      'updateProgress': '更新进度',
      'rewardLabel': '奖励',
      'goalLog': '推进记录',
      'readingTitle': '阅读',
      'bookshelf': '书架',
      'addBook': '添加书籍',
      'noteExcerpt': '摘抄',
      'noteInsight': '心得',
      'noteThought': '思考',
      'noteChange': '改变',
      'newReadingNote': '新建笔记',
      'murmurTitle': '碎碎念',
      'murmurHint': '此刻在想什么...',
      'murmurSave': '记下',
      'settings': '设置',
      'backupRestore': '备份与恢复',
      'dataExport': '数据导出',
      'themeSetting': '主题设置',
      'appLock': '应用锁',
      'about': '关于',
      'languageSetting': '语言设置',
      'languageSubtitle': '切换应用显示语言',
      'dataManagement': '数据管理',
      'securityPrivacy': '安全与隐私',
      'appearance': '外观',
      'aboutSection': '关于',
      'lastBackupNever': '上次备份：从未',
      'exportAsMarkdown': '导出为 Markdown 文件',
      'appLockSubtitle': '使用指纹/PIN保护应用',
      'wechatLoginLabel': '微信登录',
      'phoneLoginLabel': '手机号登录',
      'unbound': '未绑定',
      'userIdLabel': '用户 ID',
      'phoneNumberLabel': '手机号',
      'registerTimeLabel': '注册时间',
      'lastLoginLabel': '最近登录',
      'exportingData': '正在导出数据…',
      'exportSuccess': '导出成功：',
      'exportFailed': '导出失败：',
      'logout': '退出登录',
      'logoutButton': '退出',
      'logoutConfirmMsg': '退出后本地数据不会删除，重新登录可继续使用。',
      'themeSystem': '跟随系统',
      'themeLight': '浅色模式',
      'themeDark': '深色模式',
      'themeSystemSubtitle': '根据系统设置自动切换深浅色',
      'themeLightSubtitle': '始终使用浅色主题',
      'themeDarkSubtitle': '始终使用深色主题',
      'save': '保存',
      'cancel': '取消',
      'delete': '删除',
      'edit': '编辑',
      'confirm': '确认',
      'search': '搜索',
      'searchHint': '输入关键词搜索',
      'noData': '还没有记录，开始写下第一条吧',
      'saveSuccess': '保存成功',
      'deleteSuccess': '已删除',
      'restore': '恢复',
      'trash': '回收站',
      'tags': '标签',
      'mood': '心情',
      'weather': '天气',
      'location': '地点',
      'title': '标题',
      'content': '内容',
      'titleOptional': '标题（选填）',
      'pageNotFound': '页面不存在',
    },

    // ================================================================
    // 繁體中文
    // ================================================================
    AppLocale.zhTW: {
      'appName': 'Buildself',
      'appSlogan': '像建設新中國一樣建設自己',
      'appSloganFull': '像建設新中國一樣建設自己 — 每一次記錄都是一塊基石。',
      'welcome': '歡迎',
      'loginWechat': '微信登入',
      'loginPhone': '手機號登入',
      'phoneInputHint': '請輸入手機號',
      'codeInputHint': '請輸入驗證碼',
      'getCode': '獲取驗證碼',
      'login': '登入',
      'privacyPolicyTip': '登入即代表同意《隱私政策》和《用戶協議》',
      'tabHome': '首頁',
      'tabWork': '工作',
      'tabLife': '生活',
      'tabGoal': '目標',
      'tabReading': '閱讀',
      'tabMine': '我的',
      'goodAfternoon': '下午好',
      'goodMorning': '早上好',
      'goodEvening': '晚上好',
      'todayIs': '今天是',
      'quickRecord': '快捷記錄',
      'activeGoals': '進行中的目標',
      'recentChanges': '近期改變',
      'todayInHistory': '往日今日',
      'explorer': '探索者',
      'allItems': '全部',
      'noActiveGoals': '暫無進行中的目標',
      'noReadingChanges': '暫無閱讀改變記錄',
      'noHistoryRecords': '暫無歷史記錄',
      'workTitle': '工作',
      'workExperience': '經驗',
      'workInsight': '心得',
      'workReflection': '反思',
      'newWorkRecord': '新建工作記錄',
      'lifeTitle': '生活',
      'lifeBeauty': '美好',
      'lifeInsight': '感悟',
      'lifeReflection': '反思',
      'newLifeRecord': '新建生活記錄',
      'goalTitle': '目標管理',
      'shortTermGoal': '短期目標',
      'midTermGoal': '中期目標',
      'longTermGoal': '長期目標',
      'newGoal': '新建目標',
      'achievementWall': '成就牆',
      'updateProgress': '更新進度',
      'rewardLabel': '獎勵',
      'goalLog': '推進記錄',
      'readingTitle': '閱讀',
      'bookshelf': '書架',
      'addBook': '添加書籍',
      'noteExcerpt': '摘抄',
      'noteInsight': '心得',
      'noteThought': '思考',
      'noteChange': '改變',
      'newReadingNote': '新建筆記',
      'murmurTitle': '碎碎念',
      'murmurHint': '此刻在想什麼...',
      'murmurSave': '記下',
      'settings': '設定',
      'backupRestore': '備份與恢復',
      'dataExport': '數據匯出',
      'themeSetting': '主題設定',
      'appLock': '應用鎖',
      'about': '關於',
      'languageSetting': '語言設定',
      'languageSubtitle': '切換應用顯示語言',
      'dataManagement': '數據管理',
      'securityPrivacy': '安全與隱私',
      'appearance': '外觀',
      'aboutSection': '關於',
      'lastBackupNever': '上次備份：從未',
      'exportAsMarkdown': '匯出為 Markdown 檔案',
      'appLockSubtitle': '使用指紋/PIN保護應用',
      'wechatLoginLabel': '微信登入',
      'phoneLoginLabel': '手機號登入',
      'unbound': '未綁定',
      'userIdLabel': '用戶 ID',
      'phoneNumberLabel': '手機號',
      'registerTimeLabel': '註冊時間',
      'lastLoginLabel': '最近登入',
      'exportingData': '正在匯出數據…',
      'exportSuccess': '匯出成功：',
      'exportFailed': '匯出失敗：',
      'logout': '退出登入',
      'logoutButton': '退出',
      'logoutConfirmMsg': '退出後本地數據不會刪除，重新登入可繼續使用。',
      'themeSystem': '跟隨系統',
      'themeLight': '淺色模式',
      'themeDark': '深色模式',
      'themeSystemSubtitle': '根據系統設定自動切換深淺色',
      'themeLightSubtitle': '始終使用淺色主題',
      'themeDarkSubtitle': '始終使用深色主題',
      'save': '保存',
      'cancel': '取消',
      'delete': '刪除',
      'edit': '編輯',
      'confirm': '確認',
      'search': '搜尋',
      'searchHint': '輸入關鍵詞搜尋',
      'noData': '還沒有記錄，開始寫下第一條吧',
      'saveSuccess': '保存成功',
      'deleteSuccess': '已刪除',
      'restore': '恢復',
      'trash': '回收站',
      'tags': '標籤',
      'mood': '心情',
      'weather': '天氣',
      'location': '地點',
      'title': '標題',
      'content': '內容',
      'titleOptional': '標題（選填）',
      'pageNotFound': '頁面不存在',
    },

    // ================================================================
    // English
    // ================================================================
    AppLocale.enUS: {
      'appName': 'Buildself',
      'appSlogan': 'Build yourself like building a new nation',
      'appSloganFull': 'Build yourself like building a new nation — every record is a cornerstone.',
      'welcome': 'Welcome',
      'loginWechat': 'WeChat Login',
      'loginPhone': 'Phone Login',
      'phoneInputHint': 'Enter phone number',
      'codeInputHint': 'Enter verification code',
      'getCode': 'Get Code',
      'login': 'Login',
      'privacyPolicyTip': 'By logging in, you agree to the Privacy Policy and User Agreement',
      'tabHome': 'Home',
      'tabWork': 'Work',
      'tabLife': 'Life',
      'tabGoal': 'Goals',
      'tabReading': 'Reading',
      'tabMine': 'Me',
      'goodAfternoon': 'Good afternoon',
      'goodMorning': 'Good morning',
      'goodEvening': 'Good evening',
      'todayIs': 'Today is',
      'quickRecord': 'Quick Record',
      'activeGoals': 'Active Goals',
      'recentChanges': 'Recent Changes',
      'todayInHistory': 'On This Day',
      'explorer': 'Explorer',
      'allItems': 'All',
      'noActiveGoals': 'No active goals',
      'noReadingChanges': 'No reading changes',
      'noHistoryRecords': 'No history records',
      'workTitle': 'Work',
      'workExperience': 'Experience',
      'workInsight': 'Insight',
      'workReflection': 'Reflection',
      'newWorkRecord': 'New Work Record',
      'lifeTitle': 'Life',
      'lifeBeauty': 'Beauty',
      'lifeInsight': 'Insight',
      'lifeReflection': 'Reflection',
      'newLifeRecord': 'New Life Record',
      'goalTitle': 'Goal Management',
      'shortTermGoal': 'Short-term Goals',
      'midTermGoal': 'Mid-term Goals',
      'longTermGoal': 'Long-term Goals',
      'newGoal': 'New Goal',
      'achievementWall': 'Achievement Wall',
      'updateProgress': 'Update Progress',
      'rewardLabel': 'Reward',
      'goalLog': 'Progress Log',
      'readingTitle': 'Reading',
      'bookshelf': 'Bookshelf',
      'addBook': 'Add Book',
      'noteExcerpt': 'Excerpt',
      'noteInsight': 'Insight',
      'noteThought': 'Thought',
      'noteChange': 'Change',
      'newReadingNote': 'New Note',
      'murmurTitle': 'Murmurs',
      'murmurHint': 'What are you thinking...',
      'murmurSave': 'Save',
      'settings': 'Settings',
      'backupRestore': 'Backup & Restore',
      'dataExport': 'Data Export',
      'themeSetting': 'Theme',
      'appLock': 'App Lock',
      'about': 'About',
      'languageSetting': 'Language',
      'languageSubtitle': 'Switch app display language',
      'dataManagement': 'Data Management',
      'securityPrivacy': 'Security & Privacy',
      'appearance': 'Appearance',
      'aboutSection': 'About',
      'lastBackupNever': 'Last backup: Never',
      'exportAsMarkdown': 'Export as Markdown file',
      'appLockSubtitle': 'Protect app with fingerprint/PIN',
      'wechatLoginLabel': 'WeChat',
      'phoneLoginLabel': 'Phone',
      'unbound': 'Not bound',
      'userIdLabel': 'User ID',
      'phoneNumberLabel': 'Phone',
      'registerTimeLabel': 'Registered',
      'lastLoginLabel': 'Last Login',
      'exportingData': 'Exporting data...',
      'exportSuccess': 'Export successful: ',
      'exportFailed': 'Export failed: ',
      'logout': 'Log Out',
      'logoutButton': 'Log Out',
      'logoutConfirmMsg': 'Local data will not be deleted after logout. Log in again to continue.',
      'themeSystem': 'Follow System',
      'themeLight': 'Light Mode',
      'themeDark': 'Dark Mode',
      'themeSystemSubtitle': 'Auto switch based on system setting',
      'themeLightSubtitle': 'Always use light theme',
      'themeDarkSubtitle': 'Always use dark theme',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'confirm': 'Confirm',
      'search': 'Search',
      'searchHint': 'Enter keywords to search',
      'noData': 'No records yet. Start writing your first one.',
      'saveSuccess': 'Saved successfully',
      'deleteSuccess': 'Deleted',
      'restore': 'Restore',
      'trash': 'Trash',
      'tags': 'Tags',
      'mood': 'Mood',
      'weather': 'Weather',
      'location': 'Location',
      'title': 'Title',
      'content': 'Content',
      'titleOptional': 'Title (optional)',
      'pageNotFound': 'Page not found',
    },
  };
}
