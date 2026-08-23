import 'package:flutter/material.dart';
import 'package:buildself/core/constants/app_constants.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';

/// 关于页
class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.about)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.eco, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                AppConstants.appName,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'v${AppConstants.appVersion}',
                style: TextStyle(fontSize: 14, color: textSecondary),
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.appSlogan,
                style: TextStyle(fontSize: 15, color: textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Text(
                '建设自己，是一场最值得的投资',
                style: TextStyle(fontSize: 13, color: textSecondary, height: 1.8),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
