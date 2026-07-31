import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/shared/widgets/nexus_background.dart';

/// 登录页 — NEXUS 接入终端
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPhoneMode = false;
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// 微信登录（本地化模拟）
  Future<void> _loginWithWechat() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<AppProvider>();
      await provider.loginWithWechat(
        openId: 'local_wechat_${DateTime.now().millisecondsSinceEpoch}',
        nickname: '微信用户',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登录失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 手机号登录
  Future<void> _loginWithPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入正确的11位手机号')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final provider = context.read<AppProvider>();
      await provider.loginWithPhone(phone);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登录失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: NexusBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                // HUD 标签
                _buildHudLabel(_isPhoneMode ? '// PHONE AUTH' : '// SELECT METHOD'),
                const SizedBox(height: 12),

                // 标题
                Text(
                  _isPhoneMode ? AppStrings.loginPhone : '接入 Buildself',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryDark,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '选择你的身份认证方式以继续',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryDark,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 36),

                if (!_isPhoneMode) ...[
                  // 微信登录
                  _buildSocialButton(
                    icon: Icons.wechat,
                    label: AppStrings.loginWechat,
                    color: const Color(0xFF07C160),
                    onPressed: _isLoading ? null : _loginWithWechat,
                  ),
                  const SizedBox(height: 14),

                  // 手机号登录
                  _buildSocialButton(
                    icon: Icons.phone_android,
                    label: AppStrings.loginPhone,
                    color: AppColors.primary,
                    onPressed: () => setState(() => _isPhoneMode = true),
                  ),
                ] else ...[
                  // 手机号输入
                  _buildTextFieldLabel('手机号'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                    style: const TextStyle(color: AppColors.textPrimaryDark, letterSpacing: 2),
                    decoration: const InputDecoration(
                      hintText: AppStrings.phoneInputHint,
                      prefixIcon: Icon(Icons.phone_android),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 验证码
                  _buildTextFieldLabel('验证码'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: const TextStyle(color: AppColors.textPrimaryDark, letterSpacing: 4),
                          decoration: const InputDecoration(
                            hintText: AppStrings.codeInputHint,
                            prefixIcon: Icon(Icons.lock_outline),
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('验证码已发送（本地模式请输入任意6位数字）')),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary.withOpacity(0.6), width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(AppStrings.getCode, style: TextStyle(fontSize: 13, letterSpacing: 0.5)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 登录按钮
                  _buildPrimaryButton(
                    onPressed: _isLoading ? null : _loginWithPhone,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.spaceDeep),
                          )
                        : const Text(AppStrings.login,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 2)),
                  ),
                  const SizedBox(height: 14),

                  // 返回其他方式
                  TextButton(
                    onPressed: () => setState(() => _isPhoneMode = false),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.arrow_back_ios, size: 12),
                        SizedBox(width: 6),
                        Text('其他登录方式', style: TextStyle(letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),
                Text(
                  AppStrings.privacyPolicyTip,
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondaryDark.withOpacity(0.7), letterSpacing: 0.3),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHudLabel(String text) {
    return Row(
      children: [
        Container(width: 18, height: 1.2, color: AppColors.primary.withOpacity(0.6)),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 2,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildTextFieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondaryDark,
        letterSpacing: 1.5,
        fontFamily: 'monospace',
      ),
    );
  }

  /// 第三方登录按钮 — 玻璃卡片
  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: color.withOpacity(0.18), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              foregroundColor: color,
              backgroundColor: AppColors.spaceHigh,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: color.withOpacity(0.5), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 24, color: color),
                const SizedBox(width: 10),
                Text(label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 1,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 主登录按钮 — 霓虹青光晕
  Widget _buildPrimaryButton({required VoidCallback? onPressed, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.glowCyan, blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: child,
        ),
      ),
    );
  }
}
