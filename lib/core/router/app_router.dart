import 'package:flutter/material.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/shared/layouts/main_scaffold.dart';
import 'package:buildself/features/auth/screens/welcome_screen.dart';
import 'package:buildself/features/auth/screens/login_screen.dart';
import 'package:buildself/features/work/screens/work_list_screen.dart';
import 'package:buildself/features/work/screens/work_detail_screen.dart';
import 'package:buildself/features/work/screens/work_edit_screen.dart';
import 'package:buildself/features/work/screens/work_stats_screen.dart';
import 'package:buildself/data/models/work_note_model.dart';
import 'package:buildself/data/models/goal_model.dart';
import 'package:buildself/data/models/reading_models.dart';
import 'package:buildself/features/life/screens/life_list_screen.dart';
import 'package:buildself/features/life/screens/life_edit_screen.dart';
import 'package:buildself/features/goal/screens/goal_board_screen.dart';
import 'package:buildself/features/goal/screens/goal_detail_screen.dart';
import 'package:buildself/features/goal/screens/goal_edit_screen.dart';
import 'package:buildself/features/goal/screens/goal_stats_screen.dart';
import 'package:buildself/features/goal/screens/achievement_wall_screen.dart';
import 'package:buildself/features/reading/screens/bookshelf_screen.dart';
import 'package:buildself/features/reading/screens/book_detail_screen.dart';
import 'package:buildself/features/reading/screens/book_add_screen.dart';
import 'package:buildself/features/reading/screens/note_edit_screen.dart';
import 'package:buildself/features/reading/guide/reading_guide_screen.dart';
import 'package:buildself/features/reading/guide/reading_guide_detail_screen.dart';
import 'package:buildself/features/murmur/screens/murmur_screen.dart';
import 'package:buildself/features/search/screens/search_screen.dart';
import 'package:buildself/features/todo/screens/todo_list_screen.dart';
import 'package:buildself/features/todo/screens/todo_stats_screen.dart';
import 'package:buildself/features/todo/screens/category_manage_screen.dart';
import 'package:buildself/features/habit/screens/habit_list_screen.dart';
import 'package:buildself/features/habit/screens/habit_stats_screen.dart';
import 'package:buildself/features/habit/screens/habit_overview_screen.dart';
import 'package:buildself/features/profile/screens/profile_center_screen.dart';
import 'package:buildself/features/profile/screens/profile_screen.dart';
import 'package:buildself/features/profile/screens/statistics_screen.dart';
import 'package:buildself/features/profile/screens/achievements_screen.dart';
import 'package:buildself/features/settings/screens/settings_screen.dart';
import 'package:buildself/features/settings/screens/theme_setting_screen.dart';
import 'package:buildself/features/settings/screens/about_screen.dart';
import 'package:buildself/features/settings/screens/backup_screen.dart';
import 'package:buildself/features/settings/screens/trash_screen.dart';
import 'package:buildself/features/settings/screens/language_setting_screen.dart';

/// 应用路由配置
///
/// 使用 Navigator 2.0 风格的命名路由
class AppRouter {
  AppRouter._();

  /// 生成路由
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // 认证流程
      case AppRoutes.welcome:
        return _buildRoute(const WelcomeScreen(), settings);
      case AppRoutes.login:
        return _buildRoute(const LoginScreen(), settings);

      // 主框架
      case AppRoutes.main:
        return _buildRoute(const MainScaffold(), settings);

      // 工作模块
      case AppRoutes.workList:
        return _buildRoute(const WorkListScreen(), settings);
      case AppRoutes.workDetail:
        final id = settings.arguments as String?;
        return _buildRoute(WorkDetailScreen(noteId: id), settings);
      case AppRoutes.workEdit:
        final note = settings.arguments as WorkNote?;
        return _buildRoute(WorkEditScreen(note: note), settings);
      case AppRoutes.workStats:
        return _buildRoute(const WorkStatsScreen(), settings);

      // 生活模块
      case AppRoutes.lifeList:
        return _buildRoute(const LifeListScreen(), settings);
      case AppRoutes.lifeEdit:
        return _buildRoute(const LifeEditScreen(), settings);

      // 目标模块
      case AppRoutes.goalBoard:
        return _buildRoute(const GoalBoardScreen(), settings);
      case AppRoutes.goalDetail:
        final id = settings.arguments as String?;
        return _buildRoute(GoalDetailScreen(goalId: id), settings);
      case AppRoutes.goalEdit:
        final goal = settings.arguments as Goal?;
        return _buildRoute(GoalEditScreen(goal: goal), settings);
      case AppRoutes.goalStats:
        return _buildRoute(const GoalStatsScreen(), settings);
      case AppRoutes.achievementWall:
        return _buildRoute(const AchievementWallScreen(), settings);

      // 阅读模块
      case AppRoutes.bookshelf:
        return _buildRoute(const BookshelfScreen(), settings);
      case AppRoutes.bookDetail:
        final id = settings.arguments as String?;
        return _buildRoute(BookDetailScreen(bookId: id), settings);
      case AppRoutes.bookAdd:
        final book = settings.arguments as Book?;
        return _buildRoute(BookAddScreen(book: book), settings);
      case AppRoutes.noteEdit:
        final args = settings.arguments as NoteEditArgs?;
        return _buildRoute(NoteEditScreen(args: args), settings);
      case AppRoutes.readingGuide:
        return _buildRoute(const ReadingGuideScreen(), settings);
      case AppRoutes.readingGuideDetail:
        final index = settings.arguments as int? ?? 0;
        return _buildRoute(ReadingGuideDetailScreen(index: index), settings);

      // 碎碎念模块
      case AppRoutes.murmur:
        return _buildRoute(const MurmurScreen(), settings);

      // 搜索
      case AppRoutes.search:
        return _buildRoute(const SearchScreen(), settings);

      // 待办模块
      case AppRoutes.todoList:
        return _buildRoute(const TodoListScreen(), settings);
      case AppRoutes.todoStats:
        return _buildRoute(const TodoStatsScreen(), settings);
      case AppRoutes.todoCategories:
        return _buildRoute(const CategoryManageScreen(), settings);

      // 习惯打卡模块
      case AppRoutes.habitList:
        return _buildRoute(const HabitListScreen(), settings);
      case AppRoutes.habitStats:
        final habitId = settings.arguments as String? ?? '';
        return _buildRoute(HabitStatsScreen(habitId: habitId), settings);
      case AppRoutes.habitOverview:
        return _buildRoute(const HabitOverviewScreen(), settings);

      // 个人中心
      case AppRoutes.profileCenter:
        return _buildRoute(const ProfileCenterScreen(), settings);
      case AppRoutes.profile:
        return _buildRoute(const ProfileScreen(), settings);
      case AppRoutes.statistics:
        return _buildRoute(const StatisticsScreen(), settings);
      case AppRoutes.achievements:
        return _buildRoute(const AchievementsScreen(), settings);

      // 设置
      case AppRoutes.settings:
        return _buildRoute(const SettingsScreen(), settings);
      case AppRoutes.theme:
        return _buildRoute(const ThemeSettingScreen(), settings);
      case AppRoutes.about:
        return _buildRoute(const AboutScreen(), settings);
      case AppRoutes.backup:
        return _buildRoute(const BackupScreen(), settings);
      case AppRoutes.trash:
        return _buildRoute(const TrashScreen(), settings);
      case AppRoutes.language:
        return _buildRoute(const LanguageSettingScreen(), settings);

      // 默认
      default:
        return _buildRoute(
          Scaffold(
            appBar: AppBar(title: Text(AppStrings.pageNotFound)),
            body: Center(child: Text('404 - Page Not Found')),
          ),
          settings,
        );
    }
  }

  static MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}

/// 初始路由判断
///
/// 已登录用户直接进入主界面，未登录用户进入欢迎页
String get initialRoute => AppRoutes.welcome;
