import 'package:uuid/uuid.dart';
import 'package:buildself/data/database/database_provider.dart';
import 'package:buildself/data/database/tables.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/user_model.dart';

/// 认证仓库 — 管理用户登录与本地身份
class AuthRepository {
  final DatabaseProvider _db = DatabaseProvider.instance;
  final _uuid = const Uuid();

  /// 微信登录（本地化适配）
  ///
  /// 获取微信 openid 和昵称头像后，在本地创建/匹配用户
  Future<UserModel> loginWithWechat({
    required String openId,
    required String nickname,
    String? avatarPath,
  }) async {
    // 检查是否已有该微信用户
    final existing = await _db.queryOne(
      AppTables.users,
      where: 'wechat_open_id = ?',
      whereArgs: [openId],
    );

    if (existing != null) {
      // 更新最后登录时间
      final user = UserModel.fromMap(existing);
      user.lastLoginAt = DateTime.now();
      await _db.update(AppTables.users, user.toMap(),
          where: 'user_id = ?', whereArgs: [user.userId]);
      return user;
    }

    // 创建新用户
    final user = UserModel(
      userId: _uuid.v4(),
      loginType: LoginType.wechat,
      wechatOpenId: openId,
      nickname: nickname,
      avatarPath: avatarPath,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    await _db.insert(AppTables.users, user.toMap());
    return user;
  }

  /// 手机号登录（本地化适配）
  ///
  /// 纯本地模式下，验证码为模拟验证
  Future<UserModel> loginWithPhone({required String phone}) async {
    // 检查是否已有该手机号用户
    final existing = await _db.queryOne(
      AppTables.users,
      where: 'phone = ?',
      whereArgs: [phone],
    );

    if (existing != null) {
      final user = UserModel.fromMap(existing);
      user.lastLoginAt = DateTime.now();
      await _db.update(AppTables.users, user.toMap(),
          where: 'user_id = ?', whereArgs: [user.userId]);
      return user;
    }

    // 创建新用户
    final user = UserModel(
      userId: _uuid.v4(),
      loginType: LoginType.phone,
      phone: phone,
      nickname: '用户${phone.substring(phone.length - 4)}',
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    await _db.insert(AppTables.users, user.toMap());
    return user;
  }

  /// 获取当前用户
  Future<UserModel?> getCurrentUser(String userId) async {
    final map = await _db.queryOne(
      AppTables.users,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return map != null ? UserModel.fromMap(map) : null;
  }

  /// 更新用户信息
  Future<void> updateUser(UserModel user) async {
    await _db.update(AppTables.users, user.toMap(),
        where: 'user_id = ?', whereArgs: [user.userId]);
  }
}
