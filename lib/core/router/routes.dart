/// 路由名称常量
class AppRoutes {
  AppRoutes._();

  // 认证
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String login = '/login';

  // 主框架
  static const String main = '/main';

  // 首页子页面
  static const String home = '/home';

  // 待办模块
  static const String todoList = '/todo';
  static const String todoStats = '/todo/stats';
  static const String todoCategories = '/todo/categories';

  // 习惯打卡模块
  static const String habitList = '/habit';
  static const String habitStats = '/habit/stats';
  static const String habitOverview = '/habit/overview';

  // 工作模块
  static const String workList = '/work';
  static const String workDetail = '/work/detail';
  static const String workEdit = '/work/edit';

  // 生活模块
  static const String lifeList = '/life';
  static const String lifeDetail = '/life/detail';
  static const String lifeEdit = '/life/edit';

  // 目标模块
  static const String goalBoard = '/goal';
  static const String goalDetail = '/goal/detail';
  static const String goalEdit = '/goal/edit';
  static const String goalStats = '/goal/stats';
  static const String achievementWall = '/goal/achievements';

  // 阅读模块
  static const String bookshelf = '/reading';
  static const String bookDetail = '/reading/book';
  static const String bookAdd = '/reading/book/add';
  static const String noteEdit = '/reading/note/edit';
  static const String readingGuide = '/reading/guide';
  static const String readingGuideDetail = '/reading/guide/detail';

  // 碎碎念模块
  static const String murmur = '/murmur';

  // 设置
  static const String settings = '/settings';
  static const String backup = '/settings/backup';
  static const String theme = '/settings/theme';
  static const String about = '/settings/about';
  static const String trash = '/settings/trash';
  static const String language = '/settings/language';

  // 搜索
  static const String search = '/search';

  // 个人中心
  static const String profileCenter = '/profile';
  static const String profile = '/profile/info';
  static const String statistics = '/profile/statistics';
  static const String achievements = '/profile/achievements';
}
