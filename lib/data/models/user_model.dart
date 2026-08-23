import 'package:buildself/data/models/enums.dart';

/// 用户模型
class UserModel {
  final String userId;
  final LoginType loginType;
  final String? phone;
  final String? wechatOpenId;
  String nickname;
  String? avatarPath;
  final DateTime createdAt;
  DateTime lastLoginAt;

  UserModel({
    required this.userId,
    required this.loginType,
    this.phone,
    this.wechatOpenId,
    required this.nickname,
    this.avatarPath,
    required this.createdAt,
    required this.lastLoginAt,
  });

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'login_type': loginType.name,
        'phone': phone,
        'wechat_open_id': wechatOpenId,
        'nickname': nickname,
        'avatar_path': avatarPath,
        'created_at': createdAt.toIso8601String(),
        'last_login_at': lastLoginAt.toIso8601String(),
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        userId: map['user_id'] as String,
        loginType: LoginType.values.firstWhere(
          (e) => e.name == map['login_type'],
          orElse: () => LoginType.phone,
        ),
        phone: map['phone'] as String?,
        wechatOpenId: map['wechat_open_id'] as String?,
        nickname: map['nickname'] as String,
        avatarPath: map['avatar_path'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        lastLoginAt: DateTime.parse(map['last_login_at'] as String),
      );
}
